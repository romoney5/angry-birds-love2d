--resources: sounds
audiochannels = nil
cachedaudios = {}
audios = {}

channelVolumes = {}

function res.createAudioOutput(channels, bitrate, samplerate)
	print("Created audio output: "..(channels == 1 and "Mono" or "Stereo")..", "..bitrate.."-bit, "..(samplerate / 1000).."kHz")
	accurateAudioSpeed._hz = samplerate

	audiochannels = {}
	for i = 1, 10 do
		table.insert(audiochannels, {})
		channelVolumes[i] = 1
	end
end

function res.createAudio(path, name, streamed)
	audios[name] = datapath.."/"..path
end

function createAudioFromLua(path, name, streamed)--?
	audios[name] = datapath.."/"..path
end

function res.createCompositeAudio(name, list) --absw.. not sure why they had to repeat the same audio 59 times
	audios[name] = audios[list[1]]
end

function res.isAudioPlaying(audio)
	if not audiochannels or not cachedaudios[audio] or cachedaudios[audio] == 0 then
		return false
	end

	for i, channel in ipairs(audiochannels) do
		for ii, sound in ipairs(channel) do
			if sound.name == audio and sound.source:isPlaying() then
				return true
			end
		end
	end

	return false
end

function res.playAudio(audio, volume, loop, track)
	-- assert(audiochannels, "Trying to play audio clip but no audio output has been created")

	if not audiochannels then return end
	if not audios[audio] then return end
	if cachedaudios[audio] == 0 then return end
	
	local audioStreamAllowed = true
	local maxChannel = 7 --10 -- NOTE : this must be increased for newer versions.
	maxChannel = 10
	local channel = 1
	
	if track then
		channel = track + 1
		assert(audiochannels[channel] ~= nil, "Track " .. track .. " out of bounds! Range [0-9]")
		if #audiochannels[channel] >= maxChannel then
			audioStreamAllowed = false
		end
	else
		if #audiochannels[channel] >= maxChannel then
			local availableChannel = 2
			local channelFound = false
			
			while availableChannel <= #audiochannels do
				if #audiochannels[availableChannel] < maxChannel then
					channel = availableChannel
					channelFound = true
					break
				end
				availableChannel = availableChannel + 1
			end
			
			audioStreamAllowed = channelFound
		end
	end
	
	--actually load audios when it's time to play them
	if not cachedaudios[audio] then
		if not checkDirectory(audios[audio]) then
			cachedaudios[audio] = 0
			print("Audio file \""..audios[audio].."\" not found.")
			return
		end

		--if the audio loops it's likely that it should be streamed from disk
		--wrap it in a pcall in case love throws a tantrum
		if not pcall(function() cachedaudios[audio] = love.audio.newSource(audios[audio], loop and "stream" or "static") end) then
			cachedaudios[audio] = 0
			print("Audio file \""..audios[audio].."\" could not be decoded.")
			return
		end
	end

	if audioStreamAllowed then
		local source = cachedaudios[audio]:clone()
		source:setLooping(loop or false)

		if accurateAudioSpeed.on then
			source:setPitch(audioSpeed * (accurateAudioSpeed._hz / (cachedaudios[audio]:getDuration("samples") / cachedaudios[audio]:getDuration("seconds"))))
		else
			source:setPitch(audioSpeed)
		end

		if volume then
			source:setVolume(volume * channelVolumes[channel])
		else
			source:setVolume(channelVolumes[channel])
		end
		
		source:play()

		table.insert(audiochannels[channel], {name = audio, source = source, volume = volume or 1})
	end
end

local res_playAudio = res.playAudio
function ResourceManager.native_playAudio(audio, volume, flag, channel)
	res_playAudio(audio, volume)
end

function ResourceManager.native_createAudio(path, name)
	res.createAudio(path, name)
end

function res.stopAudio(audio)
	if not audiochannels or not cachedaudios[audio] or cachedaudios[audio] == 0 then
		return
	end

	for i, channel in ipairs(audiochannels) do
		for ii, sound in ipairs(channel) do
			if sound.name == audio then
				local source = sound.source
				source:stop()
				return
			end
		end
	end
end

function res.setTrackVolume(vol, track)
	local channel = track + 1
	channelVolumes[channel] = math.min(math.max(vol, 0), 1)

	if audiochannels then
		for i, sound in ipairs(audiochannels[channel]) do
			sound.source:setVolume(sound.volume * vol)
		end
	end
end

function res.getTrackVolume(track)
	local channel = track + 1
	return channelVolumes[channel]
end

function res.stopAllAudio()
	love.audio.stop()

	if audiochannels then
		for k, _ in ipairs(audiochannels) do
			table.clear(audiochannels[k])
		end
	end
end

function res.stopAudioOutput()
	return
end

function res.startAudioOutput()
	return
end
