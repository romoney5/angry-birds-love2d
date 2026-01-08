--resources: sounds
audiochannels = nil
cachedaudios = {}
audios = {}

function res.createAudioOutput(channels,bitrate,samplerate)
	print("Created audio output: "..(channels == 1 and "Mono" or "Stereo")..", "..bitrate.."-bit, "..(samplerate / 1000).."kHz")
	accurateAudioSpeed._hz = samplerate

	audiochannels = {}
	for i = 1, 10 do
		table.insert(audiochannels, {})
	end
end

function res.createAudio(path,name)
	audios[name] = datapath.."/"..path
end

function res.createCompositeAudio(name,list) --star wars.. not sure why they had to repeat the same audio 59 times
	audios[name] = audios[list[1]]
end

function res.isAudioPlaying(audio)
	if audios[audio] and cachedaudios[audio] and cachedaudios[audio] ~= 0 then
		return cachedaudios[audio]:isPlaying()
	end
	return false
end

function res.playAudio(audio, volume, loop, track)
	-- assert(audiochannels, "Trying to play audio clip but no audio output has been created")

	if not audiochannels then return end
	if not audios[audio] then return end
	if cachedaudios[audio] == 0 then return end
	
	local audioStreamAllowed = true
	local maxChannel = 7
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
				if #audiochannels[availableChannel] <= maxChannel then
					channel = availableChannel
					channelFound = true
					break
				end
				availableChannel = availableChannel + 1
			end
			
			audioStreamAllowed = channelFound
		end
	end
	
	if not cachedaudios[audio] then
		if not checkDirectory(audios[audio]) then
			cachedaudios[audio] = 0
			print("Audio file \""..audios[audio].."\" not found.")
			return
		end
		cachedaudios[audio] = love.audio.newSource(audios[audio], loop and "stream" or "static") --for looping audio, stream from disk rather than in memory
	end

	if audioStreamAllowed then
		cachedaudios[audio]:setLooping(loop or false)
		if accurateAudioSpeed.on then
			cachedaudios[audio]:setPitch(audioSpeed * (accurateAudioSpeed._hz / (cachedaudios[audio]:getDuration("samples") / cachedaudios[audio]:getDuration("seconds"))))
		else
			cachedaudios[audio]:setPitch(audioSpeed)
		end
		cachedaudios[audio]:setVolume(volume)
		res.stopAudio(audio)
		cachedaudios[audio]:play()
		table.insert(audiochannels[channel], audio)
	end
end

function ResourceManager.native_playAudio(audio, volume, flag, channel)
	res.playAudio(audio, volume)
end

function ResourceManager.native_createAudio(path, name)
	res.createAudio(path, name)
end

function res.stopAudio(audio)
	if not cachedaudios[audio] or cachedaudios[audio] == 0 then
		return
	end
	cachedaudios[audio]:stop()
end

function res.setTrackVolume(vol,track)
	audiovolume = vol
end

function res.getTrackVolume(track)
	return love.audio.getVolume()
end

function res.stopAllAudio()
	love.audio.stop()

	if audiochannels then
		for k, _ in ipairs(audiochannels) do
			audiochannels[k] = {}
		end
	end
end

function res.stopAudioOutput()
	return
end

function res.startAudioOutput()
	return
end