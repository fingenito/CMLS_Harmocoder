/*
  ==============================================================================

    Distortion.cpp
    Created: 10 May 2024 12:48:54pm
    Author:  PC

  ==============================================================================
*/

#include "Distortion.h"

template <typename SampleType>  
Distortion<SampleType>::Distortion()
{

}

template <typename SampleType>
void Distortion<SampleType>::prepare(juce::dsp::ProcessSpec &spec)
{
    _sampleRate = spec.sampleRate;

    _dcFilter.prepare(spec);
    _dcFilter.setCutoffFrequency(10.0);
    _dcFilter.setType(juce::dsp::LinkwitzRileyFilter<float>::Type::highpass);

    _sideChainFilterLeft.prepare(spec);
    _sideChainFilterLeft.setCutoffFrequency(1000.0);
    _sideChainFilterLeft.setType(juce::dsp::LinkwitzRileyFilter<float>::Type::highpass);

    _sideChainFilterRight.prepare(spec);
    _sideChainFilterRight.setCutoffFrequency(1000.0);
    _sideChainFilterRight.setType(juce::dsp::LinkwitzRileyFilter<float>::Type::highpass);

    reset();
}

template <typename SampleType>
void Distortion<SampleType>::reset()
{
    if (_sampleRate <= 0) return;

    _input.reset(_sampleRate, 0.02);
    _input.setTargetValue(0.0);

    _mix.reset(_sampleRate, 0.02);
    _mix.setTargetValue(1.0);

    _output.reset(_sampleRate, 0.02);
    _output.setTargetValue(0.0);
}

template <typename SampleType>
void Distortion<SampleType>::setDrive(SampleType newDrive)
{
    _input.setTargetValue(newDrive);
}

template <typename SampleType>
void Distortion<SampleType>::setMix(SampleType newMix)
{
    _mix.setTargetValue(newMix);

}

template <typename SampleType>
void Distortion<SampleType>::setOutput(SampleType newOutput)
{
    _output.setTargetValue(newOutput);
}

template <typename SampleType>
void Distortion<SampleType>::setDristortionModel(DistortionModel newModel)
{
    switch (newModel)
    {
        case DistortionModel::kHard:
        {
            _model = newModel;
            break;
        }
        case DistortionModel::kSoft:
        {
			_model = newModel;
			break;
		}
        case DistortionModel::kSaturation:
        {
            _model = newModel;
            break;
        }
    }
}

template class Distortion<float>;
template class Distortion<double>;