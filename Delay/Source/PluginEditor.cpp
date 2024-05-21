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
    setSize(400, 300); // Imposta le dimensioni della finestra una volta sola

    addAndMakeVisible(delayTimeSlider);
    delayTimeSlider.setSliderStyle(juce::Slider::LinearHorizontal);
    delayTimeSlider.setRange(0, 1000);
    delayTimeSlider.setValue(500);
    delayTimeSlider.setBounds(10, 10, 380, 50); // Imposta le dimensioni e la posizione del primo slider

    delayTimeSlider.onValueChange = [this]()
        {
            audioProcessor.setDelayTime(delayTimeSlider.getValue());
        };

    addAndMakeVisible(feedbackSlider);
    feedbackSlider.setSliderStyle(juce::Slider::LinearHorizontal);
    feedbackSlider.setRange(0, 1);
    feedbackSlider.setValue(0.5);
    feedbackSlider.setBounds(10, 70, 380, 50); // Imposta le dimensioni e la posizione del secondo slider

    feedbackSlider.onValueChange = [this]()
        {
            audioProcessor.setFeedback(feedbackSlider.getValue());
        };
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
    g.drawFittedText ("DELAY SLIDER del diocan", 0, 0, 100, 20, juce::Justification::centred, 1);
}

void DelayAudioProcessorEditor::resized()
{
    delayTimeSlider.setBounds(50, 50, 200, 50);
}
