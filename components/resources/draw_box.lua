--drawboxnative is huge so it's here instead
--edited from 2.0.0's gamelogic.lua

function gamelua.drawBoxNative(boxSprites, x1, y1, width, height, hAnchor, vAnchor, color)
	local res = _G.res
	local r, g, b, a = 1.0, 1.0, 1.0, 1.0
	
	if color then
		r = color.red or r
		g = color.green or g
		b = color.blue or b
		a = color.alpha or a
	end

	local x2 = x1 + width - 1
	local y2 = y1 + height - 1
	
	boxSprites.topLeft = boxSprites.topLeft or ""
	boxSprites.topRight = boxSprites.topRight or ""
	boxSprites.bottomLeft = boxSprites.bottomLeft or ""
	boxSprites.center = boxSprites.center or ""
	
	boxSprites.topMiddle = boxSprites.topMiddle or ""
	boxSprites.left = boxSprites.left or ""
	boxSprites.right = boxSprites.right or ""
	boxSprites.bottomMiddle = boxSprites.bottomMiddle or ""
	
	local _, thTopMiddle = res.getSpriteBounds(boxSprites.topMiddle)
	local twMiddleLeft, _ = res.getSpriteBounds(boxSprites.left)
	local twMiddleRight, _ = res.getSpriteBounds(boxSprites.right)
	local _, thBottomMiddle = res.getSpriteBounds(boxSprites.bottomMiddle)
	
	local xPivot, yPivot = 0, 0
	
	if hAnchor == "HCENTER" then
		xPivot = -width / 2
	elseif hAnchor == "RIGHT" then
		xPivot = -width
	else -- left
		xPivot = 0
	end
	
	if vAnchor == "VCENTER" then
		yPivot = -height / 2
	elseif vAnchor == "BOTTOM" then
		yPivot = -height
	else -- top
		yPivot = 0
	end
	
	-- check if some part of the box is on screen
	if y1 - thTopMiddle + yPivot <= gamelua.screenHeight and y1 + height + yPivot + thBottomMiddle >= 0 then
		-- draw borders
		res.drawSprite(boxSprites.topMiddle, x1 + xPivot , y1 - thTopMiddle + yPivot, "TOP", "LEFT", width, thTopMiddle)
		res.drawSprite(boxSprites.bottomMiddle, x1 + xPivot , y1 + height + yPivot, "TOP", "LEFT", width, thBottomMiddle)
		res.drawSprite(boxSprites.left, x1 - twMiddleLeft + xPivot , y1 + yPivot, "TOP", "LEFT", twMiddleLeft, height)
		res.drawSprite(boxSprites.right, x1 + width + xPivot, y1 + yPivot, "TOP", "LEFT", twMiddleRight, height)
		
		-- draw corners
		res.drawSprite(boxSprites.topLeft, x1 + xPivot, y1 + yPivot, "BOTTOM", "RIGHT")
		res.drawSprite(boxSprites.topRight, x1 + width + xPivot, y1 + yPivot, "BOTTOM", "LEFT")
		res.drawSprite(boxSprites.bottomLeft, x1 + xPivot, y1 + height + yPivot, "TOP", "RIGHT")
		res.drawSprite(boxSprites.bottomRight, x1 + width + xPivot, y1 + height + yPivot, "TOP", "LEFT")
		
		-- if color isn't defined then fill with center sprite
		if color ~= nil then
			gamelua.drawRect(r, g, b, a, x1 + xPivot, y1 + yPivot, x2 + xPivot, y2 + yPivot, false)
		else
			res.drawSprite(boxSprites.center, x1 + xPivot, y1 + yPivot, "TOP", "LEFT", width, height)
		end
	end
end
