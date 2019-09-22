//I base this code in:
// - https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html
// - https://catlikecoding.com/

#if !defined(FLOW_INCLUDED)
#define FLOW_INCLUDED 

float _WaveSimulator;
half _Speed;
half4 _FirstWave, _SecondWave, _ThirdWave;

half4 WaveSimulation(half4 wave, half4 p)
{
	half steepness = wave.z;
	half waveLength = wave.w;
	half k = 2 * UNITY_PI / waveLength;
	half2 d = normalize(wave.xy);
	half f = k * (dot(d, p.xz) - _Speed * _Time.y);
	half a = steepness / k;

	p.x = d.x * a * cos(f);
	p.y = a * sin(f);
	p.z = d.y * a * cos(f);

	return p;
}

#endif