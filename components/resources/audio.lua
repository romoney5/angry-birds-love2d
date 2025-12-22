--resources: sounds

function res.createAudioOutput(channels,bitrate,samplerate)
	print("Created audio output: "..(channels == 1 and "Mono" or "Stereo")..", "..bitrate.."-bit, "..(samplerate / 1000).."kHz")
	accurateAudioSpeed._hz = samplerate
end

function res.createAudio(path,name)
	audios[name] = dataPath.."/"..path
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

local function playAudio(audio, volume, loop, track) --TODO: multi play/channels, maybe free music
	if not audios[audio] then return end
	if cachedaudios[audio] == 0 then return end
	
	if not cachedaudios[audio] then
		if not checkDirectory(audios[audio]) then
			cachedaudios[audio] = 0
			showPopup("Warning",
				"Audio "..audios[audio].." not found."
			) currentPopup.important = true
			return
		end
		cachedaudios[audio] = love.audio.newSource(audios[audio], loop and "stream" or "static") --for looping audio, stream from disk rather than in memory
	end

	cachedaudios[audio]:setLooping(loop or false)
	if accurateAudioSpeed.on then
		cachedaudios[audio]:setPitch(audioSpeed * (accurateAudioSpeed._hz / (cachedaudios[audio]:getDuration("samples") / cachedaudios[audio]:getDuration("seconds"))))
	else
		cachedaudios[audio]:setPitch(audioSpeed)
	end
	cachedaudios[audio]:setVolume(volume)
	res.stopAudio(audio)
	cachedaudios[audio]:play()
end
res.playAudio = playAudio

function ResourceManager.native_playAudio(audio, volume, flag, channel)
	playAudio(audio,volume)
end

function ResourceManager.native_createAudio(path,name)
	res.createAudio(path,name)
end

function res.stopAudio(audio)
	if not cachedaudios[audio] or cachedaudios[audio] == 0 then
		return
	end
	cachedaudios[audio]:stop()
end

function res.setTrackVolume(vol,track)
	audiovolume = vol
	-- love.audio.setVolume(vol)
end

function res.getTrackVolume(track)
	return love.audio.getVolume()
end

function res.stopAllAudio()
	love.audio.stop()
end

function res.stopAudioOutput()
	return
end

function res.startAudioOutput()
	return
end