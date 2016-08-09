/*
 * GuiApp.cpp
 *
 *  Created on: Oct 28, 2014
 *      Author: arturo
 */

#include "GuiApp.h"

void GuiApp::setup(){
	ofBackground(0);
	ofSetVerticalSync(false);
}

void GuiApp::update(){

}

void GuiApp::draw(){
	ofSetColor(ofColor::red);
	ofDrawCircle(100, 100, 100);
}

void GuiApp::exit()
{
	onExit();
	ofBaseApp::exit();
	cout << "gui exit" << endl;
}