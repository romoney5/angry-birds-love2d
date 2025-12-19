--debug: collisions list

collisionsList = {}
function drawCollisionsList()
	-- {o1 = o1.name, o2 = o2.name, veloc = veloc, damage = damage}
	for i, v in pairs(collisionsList) do
		if i >= 10 then
			table.remove(collisionsList, i)
			break
		end
		res.drawString("", v.o1.."->"..v.o2.." (V: "..v.veloc.." D: "..v.damage..") (s1: "..v.m1.." s2: "..v.m2..")", 50, i * 50 + 80)
	end
end