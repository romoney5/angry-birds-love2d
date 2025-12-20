res = {} --game resources
ResourceManager = {}

if love.graphics.newShader then res.textureShader = love.graphics.newShader([[
vec4 effect(vec4 colour, Image texture, vec2 texpos, vec2 scrpos)
{
    vec4 pixel = Texel(texture, texpos) * colour;
    if (pixel.a < 0.2) discard;
    return vec4(pixel.rgb, pixel.a);
}
]]) end

--misc

function lerp(a,b,t) return a + (b - a) * t end

function res.openURL(url)
	love.system.openURL(url)
end