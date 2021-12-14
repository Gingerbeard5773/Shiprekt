void directionalSoundPlay(string soundName, Vec2f soundPos, f32 volume = 1.0f, f32 pitch = 1.0f)//considers the camera rotation when playing sounds so they are truly directional
{
	volume *= 0.75f;
	CCamera@ camera = getCamera();
	if (camera !is null)
	{
		Vec2f camPos = camera.getPosition();
		Vec2f camVec = soundPos - camPos;
		camVec.RotateBy(-camera.getRotation());
		Sound::Play(soundName, camPos + camVec, volume, pitch);
	}
	else
		Sound::Play(soundName, soundPos, volume, pitch);
}
