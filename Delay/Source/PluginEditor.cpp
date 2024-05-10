/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
DelayAudioProcessorEditor::DelayAudioProcessorEditor (DelayAudioProcessor& p)
    : AudioProcessorEditor (&p), audioProcessor (p)
{
    addAndMakeVisible(delayTimeSlider);
    delayTimeSlider.setSliderStyle(juce::Slider::LinearHorizontal);
    delayTimeSlider.setRange(0, 1000);
    delayTimeSlider.setValue(500);

    delayTimeSlider.onValueChange = [this]()
        {
            audioProcessor.setDelayTime(delayTimeSlider.getValue());
        };

    setSize (400, 300);
}

DelayAudioProcessorEditor::~DelayAudioProcessorEditor()
{
}

//==============================================================================
void DelayAudioProcessorEditor::paint (juce::Graphics& g)
{
    // (Our component is opaque, so we must completely fill the background with a solid colour)
    g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));

    g.setColour (juce::Colours::white);
    g.setFont (15.0f);
    g.drawFittedText ("DELAY SLIDER", 0, 0, 100, 20, juce::Justification::centred, 1);
}

void DelayAudioProcessorEditor::resized()
{
    delayTimeSlider.setBounds(50, 50, 200, 50);
}
