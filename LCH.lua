local interpolateLCH do
	local bit = {}

	do
		function bit.XOR(a, b)
			local p,c=1,0
			while a>0 and b>0 do
				local ra,rb=a%2,b%2
				if ra~=rb then c=c+p end
				a,b,p=(a-ra)/2,(b-rb)/2,p*2
			end
			if a<b then a=b end
			while a>0 do
				local ra=a%2
				if ra>0 then c=c+p end
				a,p=(a-ra)/2,p*2
			end
			return c
		end 

		function bit.OR(a, b)
			local p,c=1,0
			while a+b>0 do
				local ra,rb=a%2,b%2
				if ra+rb>0 then c=c+p end
				a,b,p=(a-ra)/2,(b-rb)/2,p*2
			end
			return c
		end

		function bit.NOT(n)
			local p,c=1,0
			while n>0 do
				local r=n%2
				if r<1 then c=c+p end
				n,p=(n-r)/2,p*2
			end
			return c
		end

		function bit.AND(a, b)
			local p,c=1,0
			while a>0 and b>0 do
				local ra,rb=a%2,b%2
				if ra+rb>1 then c=c+p end
				a,b,p=(a-ra)/2,(b-rb)/2,p*2
			end
			return c
		end

		function bit.leftShift(x, by)
			return x * 2 ^ by
		end

		function bit.rightShift(x, by)
			return math.floor(x / 2 ^ by)
		end
	end

	local function bound(v, l, h)
		return math.min(h, math.max(l, v))
	end

	local function round(n, mult)
		mult = mult or 1
		return math.floor(n/mult+.5)*mult
	end

	local function makeColor(a, b, c, mode)
		mode = mode or "RGB"

		local color = {}

		local rgbDirty = true
		local hsvDirty = true
		local lchDirty = true

		local red, green, blue = 0, 0, 0

		local hue, saturation, value = 0, 0, 0

		local xyz_x, xyz_y, xyz_z = 0, 0, 0

		local lab_l, lab_a, lab_b = 0, 0, 0

		local lch_l, lch_c, lch_h = 0, 0, 0

		if a == nil then a = 0 end
		if b == nil then b = 0 end
		if c == nil then c = 0 end

		if mode == "RGB" then
			red, green, blue = bound(a, 0, 255), bound(b, 0, 255), bound(c, 0, 255)
			rgbDirty = false
		elseif mode == "HSV" then
			hue, saturation, value = bound(a, 0, 360), bound(b, 0, 100), bound(c, 0, 100)
			hsvDirty = false
		elseif mode == "LCH" then
			lch_l, lch_c = a, b
			if c < 360 then
				lch_h = c
			else
				lch = c - 360
			end
			lchDirty = false
		end

		local function convertRGBtoHSV()
			local r = red
			local g = green
			local b = blue

			local min = math.min(r, g, b)
			local max = math.max(r, g, b)

			local delta = max - min

			local h = max
			local s = max
			local v = max

			v = max / 255 * 100

			if max ~= 0 then
				s = delta / max * 100

				if r == max then
					h = (g - b) / delta
				elseif g == max then
					h = 2 + (b - r) / delta
				else
					h = 4 + (r - g) / delta
				end
			end

			hue = h
			saturation = s
			value = v
		end

		local function convertHSVtoRGB()
			local h = hue
			local s = saturation
			local v = value

			local r, g, b
			local f, p, q, t
			local i

			s = s / 100
			v = v / 100

			if s == 0 then
				r, g, b = v, v, v
			else
				h = h / 60
				i = math.floor(h)
				f = h - i
				p = v * (1 - s)
				q = v * (1 - s * f)
				t = v * (1 - s * (1 - f))

				if i == 0 then
					r = v
					g = t
					b = p
				elseif i == 1 then
					r = q
					g = v
					b = p
				elseif i == 2 then
					r = p
					g = v
					b = t
				elseif i == 3 then
					r = p
					g = q
					b = v
				elseif i == 4 then
					r = t
					g = p
					b = v
				else
					r = v
					g = p
					b = q
				end
			end

			red = bound((r * 255), 0, 255)
			green = bound((g * 255), 0, 255)
			blue = bound((b * 255), 0, 255)
		end

		local function convertRGBtoXYZ()
			local tmp_r = red / 255
			local tmp_g = green / 255
			local tmp_b = blue / 255

			if tmp_r > 0.04045 then
				tmp_r = math.pow(((tmp_r + 0.055) / 1.055), 2.4)
			else
				tmp_r = tmp_r / 12.92
			end

			if tmp_g > 0.04045 then
				tmp_g = math.pow(((tmp_g + 0.055) / 1.055), 2.4)
			else
				tmp_g = tmp_g / 12.92
			end

			if tmp_b > 0.04045 then
				tmp_b = math.pow(((tmp_b + 0.055) / 1.055), 2.4)
			else
				tmp_b = tmp_b / 12.92
			end

			tmp_r = tmp_r * 100
			tmp_g = tmp_g * 100
			tmp_b = tmp_b * 100

			local x = tmp_r * 0.4124 + tmp_g * 0.3576 + tmp_b * 0.1805
			local y = tmp_r * 0.2126 + tmp_g * 0.7152 + tmp_b * 0.0722
			local z = tmp_r * 0.0193 + tmp_g * 0.1192 + tmp_b * 0.9505

			xyz_x = x
			xyz_y = y
			xyz_z = z
		end

		local function convertXYZtoLAB()
			local Xn = 95.047
			local Yn = 100.000
			local Zn = 108.883

			local x = xyz_x / Xn
			local y = xyz_y / Yn
			local z = xyz_z / Zn

			if x > 0.008856 then
				x = math.pow(x, 1 / 3)
			else
				x = (7.787 * x) + (16 / 116)
			end

			if y > 0.008856 then
				y = math.pow(y, 1 / 3)
			else
				y = (7.787 * y) + (16 / 116)
			end

			if z > 0.008856 then
				z = math.pow(z, 1 / 3)
			else
				z = (7.787 * z) + (16 / 116)
			end

			local l

			if y > 0.008856 then
				l = (116 * y) - 16
			else
				l = 903.3 * y
			end

			local a = 500 * (x - y)
			local b = 200 * (y - z)

			lab_l = l
			lab_a = a
			lab_b = b
		end

		local function convertLABtoLCH()
			local var_H = math.atan2(lab_b, lab_a)

			if var_H > 0 then
				var_H = (var_H / math.pi) * 180
			else
				var_H = 360 - (math.abs(var_H) / math.pi) * 180
			end

			lch_l = lab_l
			lch_c = math.sqrt(math.pow(lab_a, 2) + math.pow(lab_b, 2))

			if var_H < 360 then
				lch_h = var_H
			else
				lch = var_H - 360
			end
		end

		local function convertLCHtoLAB()
			local l = lch_l
			local hradi = lch_h * (math.pi / 180)
			local a = math.cos(hradi) * lch_c
			local b = math.sin(hradi) * lch_c

			lab_l = l
			lab_a = a
			lab_b = b
		end

		local function convertLABtoXYZ()
			local ref_X = 95.047
			local ref_Y = 100.000
			local ref_Z = 108.883

			local var_Y = (lab_l + 16) / 116
			local var_X = lab_a / 500 + var_Y
			local var_Z = var_Y - lab_b / 200

			if math.pow(var_Y, 3) > 0.008856 then
				var_Y = math.pow(var_Y, 3)
			else
				var_Y = (var_Y - 16 / 116) / 7.787
			end
			if math.pow(var_X, 3) > 0.008856 then
				var_X = math.pow(var_X, 3)
			else
				var_X = (var_X - 16 / 116) / 7.787
			end
			if math.pow(var_Z, 3) > 0.008856 then
				var_Z = math.pow(var_Z, 3)
			else
				var_Z = (var_Z - 16 / 116) / 7.787
			end

			xyz_x = ref_X * var_X
			xyz_y = ref_Y * var_Y
			xyz_z = ref_Z * var_Z
		end

		local function convertXYZtoRGB()
			local var_X = xyz_x / 100
			local var_Y = xyz_y / 100
			local var_Z = xyz_z / 100

			local var_R = var_X * 3.2406 + var_Y * -1.5372 + var_Z * -0.4986
			local var_G = var_X * -0.9689 + var_Y * 1.8758 + var_Z * 0.0415
			local var_B = var_X * 0.0557 + var_Y * -0.2040 + var_Z * 1.0570

			if var_R > 0.0031308 then
				var_R = 1.055 * math.pow(var_R, (1 / 2.4)) - 0.055
			else
				var_R = 12.92 * var_R
			end

			if var_G > 0.0031308 then
				var_G = 1.055 * math.pow(var_G, (1 / 2.4)) - 0.055
			else
				var_G = 12.92 * var_G
			end

			if var_B > 0.0031308 then
				var_B = 1.055 * math.pow(var_B, (1 / 2.4)) - 0.055
			else
				var_B = 12.92 * var_B
			end

			red = bound((var_R * 255), 0, 255)
			green = bound((var_G * 255), 0, 255)
			blue = bound((var_B * 255), 0, 255)
		end

		local function convertRGBtoLCH()
			convertRGBtoXYZ()
			convertXYZtoLAB()
			convertLABtoLCH()
		end

		local function convertLCHtoRGB()
			convertLCHtoLAB()
			convertLABtoXYZ()
			convertXYZtoRGB()
		end

		local function cleanForRGB()
			if not rgbDirty then return end

			if not hsvDirty then
				convertHSVtoRGB()
			elseif not lchDirty then
				convertLCHtoRGB()
			end

			rgbDirty = false
		end

		local function cleanForHSV()
			if not hsvDirty then return end

			if not rgbDirty then
				convertRGBtoHSV()
			elseif not lchDirty then
				convertLCHtoRGB()
				convertRGBtoHSV()
			end

			hsvDirty = false
		end

		local function cleanForLCH()
			if not lchDirty then return end

			if not hsvDirty then
				convertHSVtoRGB()
				convertRGBtoLCH()
			elseif not rgbDirty then
				convertRGBtoLCH()
			end

			lchDirty = false
		end

		local function rgbModified()
			hsvDirty = true
			lchDirty = true
		end

		local function hsvModified()
			rgbDirty = true
			lchDirty = true
		end

		local function lchModified()
			rgbDirty = true
			hsvDirty = true
		end

		function color.logRGB()
			print("red:", color.getRed(), "green:", color.getGreen(), "blue:", color.getBlue())
		end

		function color.logHSV()
			print("hue:", color.getHue(), "saturation:", color.getSaturation(), "value:", color.getValue())
		end

		function color.logLCH()
			print("l:", color.getLCH_L(), "c:", color.getLCH_C(), "h:", color.getLCH_H())
		end

		function color.getHex()
			cleanForRGB()

			local tempRed = round(red)
			local tempGreen = round(green)
			local tempBlue = round(blue)

			local hex = bit.leftShift(tempRed, 16) + bit.leftShift(tempGreen, 8) + tempBlue
			local hexString = string.format("%x", hex)

			while #hexString < 6 do
				hexString = "0" .. hexString
			end

			return "#" .. hexString
		end

		function color.getRed()
			cleanForRGB()

			return red
		end

		function color.setRed(r)
			cleanForRGB()

			red = bound(r, 0, 255)

			rgbModified()
		end

		function color.getGreen()
			cleanForRGB()

			return green
		end

		function color.setGreen(g)
			cleanForRGB()

			green = bound(g, 0, 255)

			rgbModified()
		end

		function color.getBlue()
			cleanForRGB()

			return blue
		end

		function color.setBlue(b)
			cleanForRGB()

			blue = bound(b, 0, 255)

			rgbModified()
		end

		function color.getHue()
			cleanForHSV()

			return hue
		end

		function color.setHue(h)
			cleanForHSV()

			hue = bound(h, 0, 360)

			hsvModified()
		end

		function color.getSaturation()
			cleanForHSV()

			return saturation
		end

		function color.setSaturation(s)
			cleanForHSV()

			saturation = bound(s, 0, 100)

			hsvModified()
		end

		function color.getValue()
			cleanForHSV()

			return value
		end

		function color.setValue(v)
			cleanForHSV()

			value = bound(v, 0, 100)

			hsvModified()
		end

		function color.getLCH_L()
			cleanForLCH()

			return lch_l
		end

		function color.setLCH_L(l)
			cleanForLCH()

			lch_l = bound(l, 0, 100)

			lchModified()
		end

		function color.getLCH_C()
			cleanForLCH()

			return lch_c
		end

		function color.setLCH_C(c)
			cleanForLCH()

			lch_c = bound(c, 0, 100)

			lchModified()
		end

		function color.getLCH_H()
			cleanForLCH()

			return lch_h
		end

		function color.setLCH_H(h)
			cleanForLCH()

			if h < 360 then
				lch_h = h
			else
				lch_h = h - 360
			end

			lchModified()
		end

		function color.toColor3()
			return Color3.new(color.getRed()/255, color.getGreen()/255, color.getBlue()/255)
		end

		return color
	end

	function interpolateLCH(fromColor, toColor, steps)
		fromColor = makeColor(fromColor.r * 255, fromColor.g * 255, fromColor.b * 255)
		toColor = makeColor(toColor.r * 255, toColor.g * 255, toColor.b * 255)

		local colors = {}
		local interpolation = {}

		local numSteps = steps

		function interpolation.getColorAtAlpha(alpha)
			if alpha < 0 or alpha > 1 then
				print("Interpolation alpha must be between 0 and 1")
				return
			end

			local stepInterval = 1 / (numSteps + 1)
			local lowValue = math.floor(alpha / stepInterval)
			local highValue = math.ceil(alpha / stepInterval)

			if lowValue == highValue then
				local color = colors[lowValue+1]
				return Color3.fromRGB(color.getRed(), color.getGreen(), color.getBlue())
			else
				local adjustedValue = (alpha - (lowValue * stepInterval)) / stepInterval
				local lowColor = colors[lowValue+1]
				local highColor = colors[highValue+1]

				local r = lowColor.getRed() + (highColor.getRed() - lowColor.getRed()) * adjustedValue
				local g = lowColor.getGreen() + (highColor.getGreen() - lowColor.getGreen()) * adjustedValue
				local b = lowColor.getBlue() + (highColor.getBlue() - lowColor.getBlue()) * adjustedValue

				return Color3.fromRGB(r, g, b)
			end
		end

		colors[#colors+1] = fromColor

		local toH = toColor.getLCH_H()
		local fromH = fromColor.getLCH_H()
		local diff = toH - fromH

		if math.abs(diff) > 180 then
			if diff > 0 then
				fromH = fromH + 360
			else
				toH = toH + 360
			end
		end

		local stepInterval = 1 / (numSteps + 1)

		for i = 1, numSteps do
			local alpha = i * stepInterval

			local l = fromColor.getLCH_L() + (toColor.getLCH_L() - fromColor.getLCH_L()) * alpha
			local c = fromColor.getLCH_C() + (toColor.getLCH_C() - fromColor.getLCH_C()) * alpha
			local h = fromH + (toH - fromH) * alpha

			local color = makeColor(l, c, h, "LCH")

			colors[#colors+1] = color
		end

		colors[#colors+1] = toColor

		return interpolation
	end
end