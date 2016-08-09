#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
	ofBackground(255);
	ofSetCircleResolution(200);
	ofSetFullscreen(true);
}

//--------------------------------------------------------------
void ofApp::update(){

}

//--------------------------------------------------------------
void ofApp::draw(){
	if (gui != NULL)
	{
		ofSetColor(0);
		ofDrawBitmapString(ofGetFrameRate(), 20, 20);
	}
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
	if ('f' == key)
	{
		ofToggleFullscreen();
	}
	else if (' ' == key)
	{
		popupWindow();
	}
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}


void ofApp::popupWindow()
{
	if (NULL == gui)
	{
		ofGLFWWindowSettings settings;
		settings.width = 300;
		settings.height = 300;
		settings.setPosition(ofVec2f(-200, 100));
		settings.resizable = false;
		shared_ptr<ofAppBaseWindow> guiWindow = ofCreateWindow(settings);
		shared_ptr<GuiApp> guiApp(new GuiApp);

		gui = guiApp;
		gui->onExit = [this]() {
			cout << "lambda function called" << endl;
			gui.~shared_ptr();
			gui = NULL;

		};
		ofRunApp(guiWindow, guiApp);
	}
}
