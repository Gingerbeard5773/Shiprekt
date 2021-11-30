
/*   License   
© 2014-2015 Zen Laboratories

This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
*/


enum DragEventType
{
   DragStarted,
   DragMove,
   DragFinished
}

//  here is how you can add handlers for events on UI elements.
//  Your handler should be a function (you specify it's name here)
//  defined in the same file or in the class (prolly)

//	It must have the same signature as mentioned in the top part of KGUI.as

//	button.addClickListener(OnButtonClicked);
//	button.addPressStateListener(OnButtonPressed);
//	button.addHoverStateListener(OnButtonHoverStateChanged);
//	window.addDragEventListener(OnDragEvent);

	// Click callback definition
	// Parameters:
	// X - Mouse position X relative to element
	// Y - Mouse position Y relative to element
	// button - Mouse button descriptor 
	// Source
	funcdef void CLICK_CALLBACK(int, int, int,IGUIItem@);

	// Hover state changed callback definition
	// Parameters:
	// isHovered - Is the element hovered?
	// Source
	funcdef void HOVER_STATE_CHANGED_CALLBACK(bool,IGUIItem@);

	// Press state changed callback definition
	// Parameters:
	// isPressed - Is the element pressed?
	// int - What mouse button caused the event
	// Source
	funcdef void PRESS_STATE_CHANGED_CALLBACK(bool, int,IGUIItem@);

	// Drag event callback definition
	// Parameters:
	// DragEventType - see DragEventType Enum
	// Vec2f - mouse position
	// Source
	funcdef void DRAG_EVENT_CALLBACK(int, Vec2f,IGUIItem@);



interface IGUIItem{


	//Properties
	Vec2f position {get; set;}
	Vec2f localPosition {get; set;} 
	Vec2f size {get; set;}
	string name {get; set;}
	string mod {get; set;}
	bool isEnabled {get; set;}
	bool isDragable {get; set;}
	bool isHovered {get; set;}
	int draggingThresold {get; set;}
	bool isClickedWithRButton{get; set;}
	bool isClickedWithLButton{get; set;}
	//Methods
	void draw();

	void addChild(IGUIItem@ child);
	void removeChild(IGUIItem@ child);
	void clearChildren();

	//Saving GUI Props to CFG:
	//By default only local position and size are (de)serialized. Override those to (de)serialize custom things.
	void loadPos(const string modName,const f32 def_x,const f32 def_y);
	void savePos(const string modName);
	void getLocked(const string modName);
	void setLocked(const string modName,const bool lock);

	//Listeners controls
	void addClickListener(CLICK_CALLBACK@ listener);
	void removeClickListener(CLICK_CALLBACK@ listener);
	void clearClickListeners();

	void addHoverStateListener(HOVER_STATE_CHANGED_CALLBACK@ listener);
	void removeHoverStateListener(HOVER_STATE_CHANGED_CALLBACK@ listener);
	void clearHoverStateListeners();

	void addPressStateListener(PRESS_STATE_CHANGED_CALLBACK@ listener);
	void removePressStateListener(PRESS_STATE_CHANGED_CALLBACK@ listener);
	void clearPressStateListeners();

	void addDragEventListener(DRAG_EVENT_CALLBACK@ listener);
	void removeDragEventListener(DRAG_EVENT_CALLBACK@ listener);
	void clearDragEventListeners();

}

class GenericGUIItem : IGUIItem{

	//config properties
	Vec2f position {
		get { return _position;} 
		set { _position = value;}
	}
	Vec2f localPosition {
		get { return _localPosition;} 
		set { _localPosition = value;}
	} 
	Vec2f size {
		get { return _size;} 
		set { _size = value;}
	}
	string name {
		get { return _name;} 
		set { _name = value;}
	}
	string mod {
		get { return _mod;} 
		set { _mod = value;}
	}
	bool isEnabled {
		get { return _enabled;} 
		set { _enabled = value;}
	}
	bool isDragable {
		get { return _isDragable;} 
		set { _isDragable = value;}
	}
	int draggingThresold {
		get { return _dragThresold;} 
		set { _dragThresold = value;}
	}
	bool isHovered{
		get { return _isHovered;} 
		set { _isHovered = value;}
	}
	bool isClickedWithRButton{
		get { return _isClickedWithRButton;} 
		set { _isClickedWithRButton = value;}
	}
	bool isClickedWithLButton{
		get { return _isClickedWithLButton;} 
		set { _isClickedWithLButton = value;}
	}
	//backing fields
	private Vec2f _size;
	private Vec2f _localPosition;
	private bool _enabled = true;
	private string _name;
	private string _mod;
	private Vec2f _position;
	private bool _isDragable = false;
	private int _dragThresold = 2;

	//Animation
	private int[] _frameIndex;
	private int _animFreq;
	private int _frame;
	private string _image;
	private Vec2f _iDimension;

	//Mouse states ( simple cache, polly will be removed later)
	private bool _mouseLeftButtonPressed  = false;
	private bool _mouseLeftButtonReleased  = false;
	private bool _mouseRightButtonPressed  = false;
	private bool _mouseRightButtonReleased  = false;
	private bool _mouseLeftButtonHold  = false;
	private bool _mouseRightButtonHold  = false;
	private Vec2f _mousePosition;

	//GUI Element states
	private bool justPressedL = false;
	private bool justPressedR = false;	
	private bool _isHovered = false;
	private int toolTipDisp = 0;
	private int toolTipTimer = 0;
	private string toolTip;	
	private SColor tipColor;		
	private bool _isPressedWithLButton = false;
	private bool _isPressedWithRButton = false; 
	private bool _isClickedWithLButton = false;
	private bool _isClickedWithRButton = false;
	private bool _isDragging = false;
	private bool _isDragPossible = false;
	private Vec2f _dragStartPosition ;
	private Vec2f _dragCurrentPosition;
	private Vec2f _startPos;

	//Children and listeners
	private IGUIItem@[] children;
	private CLICK_CALLBACK@[] _clickListeners;
	private HOVER_STATE_CHANGED_CALLBACK@[] _hoverStateListeners;
	private PRESS_STATE_CHANGED_CALLBACK@[] _pressStateListeners;
	private DRAG_EVENT_CALLBACK@[] _dragEventListeners;


	GenericGUIItem(Vec2f v_localPosition, Vec2f v_size){
		localPosition = v_localPosition;
		position = localPosition;
		size = v_size;
	}

	/* Children GUI elements controls */

	void addChild(IGUIItem@ child){
		children.push_back(child);
	}

	void removeChild(IGUIItem@ child){
		int ndx = children.find(child);
		if(ndx>-1)
			children.removeAt(ndx);
	}

	void clearChildren(){
		for(int i = 0; i < children.length; i++){
			children.removeAt(i);
		}	
	}

	/* Listener controls */

	void addClickListener(CLICK_CALLBACK@ listener){
		_clickListeners.push_back(listener);
	};

	void removeClickListener(CLICK_CALLBACK@ listener){
		int ndx = _clickListeners.find(listener);
		if(ndx>-1)
			_clickListeners.removeAt(ndx);	
	}

	void clearClickListeners(){
		for(int i = 0; i < _clickListeners.length; i++){
			_clickListeners.removeAt(i);
		}	
	}

	void addHoverStateListener(HOVER_STATE_CHANGED_CALLBACK@ listener){
		_hoverStateListeners.push_back(listener);
	};

	void removeHoverStateListener(HOVER_STATE_CHANGED_CALLBACK@ listener){
		int ndx = _hoverStateListeners.find(listener);
		if(ndx>-1)
			_hoverStateListeners.removeAt(ndx);	
	}

	void clearHoverStateListeners(){
		for(int i = 0; i < _hoverStateListeners.length; i++){
			_hoverStateListeners.removeAt(i);
		}	
	}

	void addPressStateListener(PRESS_STATE_CHANGED_CALLBACK@ listener){
		_pressStateListeners.push_back(listener);
	}

	void removePressStateListener(PRESS_STATE_CHANGED_CALLBACK@ listener){
		int ndx = _pressStateListeners.find(listener);
		if(ndx>-1)
			_pressStateListeners.removeAt(ndx);	
	}

	void clearPressStateListeners(){
		for(int i = 0; i < _pressStateListeners.length; i++){
			_pressStateListeners.removeAt(i);
		}	
	}

	void addDragEventListener(DRAG_EVENT_CALLBACK@ listener){
		_dragEventListeners.push_back(listener);
	}
	void removeDragEventListener(DRAG_EVENT_CALLBACK@ listener){
		int ndx = _dragEventListeners.find(listener);
		if(ndx>-1)
			_dragEventListeners.removeAt(ndx);		
	}
	void clearDragEventListeners(){
		for(int i = 0; i < _dragEventListeners.length; i++){
			_dragEventListeners.removeAt(i);
		}	
	}

	private void invokeClickListeners(int x, int y, int buttonCode){
		for(int i = 0; i < _clickListeners.length; i++){
			_clickListeners[i](x,y,buttonCode,this);
		}
		if (_clickListeners.length > 0){
			if (_isPressedWithLButton){
				getLocalPlayer().getBlob().set_bool("GUIEvent",true);
			}
			else getLocalPlayer().getBlob().set_bool("GUIEvent",false);	
		}
	}

	private void invokeHoverStateListeners(bool isHovered){
		for(int i = 0; i < _hoverStateListeners.length; i++){
			_hoverStateListeners[i](isHovered,this);
		}	
	}

	private void invokePressStateListeners(bool isPressed, int buttonCode){

		for(int i = 0; i < _pressStateListeners.length; i++){
			_pressStateListeners[i](isPressed,buttonCode,this);
		}	
	}

	private void invokeDragEventListeners(int eventType, Vec2f mousepos){
		for(int i = 0; i < _dragEventListeners.length; i++){
			_dragEventListeners[i](eventType,mousepos,this);
		}	
	}

	//*Made by Labz*//
	//*worked on by Sini  and Voper*//
	
	bool calculateHover(){
		CControls@ controls = getControls();
		Vec2f mouseScrPos= getControls().getMouseScreenPos();
		Vec2f lt = position;
		Vec2f br = position+size;
		return 
			mouseScrPos.x >= lt.x && 
			mouseScrPos.x <=br.x &&
			mouseScrPos.y >= lt.y && 
			mouseScrPos.y <=br.y;
	}

	//Mouse magic
	
	void draw(){




		//State updates. WARNING: The order of evaluation is important!
		updateMouseStates();
		updateHoverStates();
		updateClickStates();
		updatePressedStates();
		updateDraggingStates();
		


		drawSelf();

		//draw children
		for(int i = 0; i < children.length; i++){
			if(!children[i].isEnabled) continue;
			children[i].position = position+children[i].localPosition;
			children[i].draw();
		}
		updateToolTipState();
	

	}

	void drawSelf(){

	}


	//Possible optimization : pass control states from the parent
	private void updateMouseStates(){
		CControls@ controls = getControls();
		//_mouseLeftButtonPressed = controls.isKeyJustPressed(KEY_LBUTTON);
		_mouseLeftButtonReleased = controls.isKeyJustReleased(KEY_LBUTTON);
		//_mouseRightButtonPressed = controls.isKeyJustPressed(KEY_RBUTTON);
		_mouseRightButtonReleased = controls.isKeyJustReleased(KEY_RBUTTON);
		_mouseLeftButtonHold = controls.isKeyPressed(KEY_LBUTTON);
		_mouseRightButtonHold = controls.isKeyPressed(KEY_RBUTTON);
		_mousePosition = controls.getMouseScreenPos();

		//Might get replaced, currently more reliable at finding just pressed state then controls.isKeyJustPressed()
		//due to way KAG does calculation there.
		if(_mouseLeftButtonHold && !justPressedL){
			_mouseLeftButtonPressed = true;
			justPressedL = true;
		}
		else if (justPressedL) _mouseLeftButtonPressed = false;
		if (!_mouseLeftButtonHold) justPressedL = false;
		if(_mouseRightButtonHold && !justPressedR){
			_mouseRightButtonPressed = true;
			justPressedR = true;
		}
		else if (justPressedR) _mouseRightButtonPressed = false;
		if (!_mouseRightButtonHold) justPressedR = false;
	}

	void updateHoverStates(){
		bool newHovered = calculateHover();
		if(newHovered != _isHovered){
			if(newHovered && !_isHovered){
				invokeHoverStateListeners(true);
			} else {
				invokeHoverStateListeners(false);
				toolTipTimer = 0;
			}
			_isHovered = newHovered;
		}
	}

	void updatePressedStates(){

		if(_isHovered && _mouseLeftButtonHold && !_isPressedWithLButton){
			_isPressedWithLButton = true;
			invokePressStateListeners(true, KEY_LBUTTON);
		}

		if(_isHovered && _mouseRightButtonHold && !_isPressedWithRButton){
			_isPressedWithRButton = true;
			invokePressStateListeners(true, KEY_RBUTTON);
		}

		if(!_mouseLeftButtonHold && _isPressedWithLButton){
			_isPressedWithLButton = false;
			invokePressStateListeners(false, KEY_LBUTTON);
		}
		
		if(!_mouseRightButtonHold && _isPressedWithRButton){
			_isPressedWithRButton = false;
			invokePressStateListeners(false, KEY_RBUTTON);
		}

		if(!_isHovered && _isPressedWithRButton){
			_isPressedWithRButton = false;
			invokePressStateListeners(false,KEY_RBUTTON);
		}

		if(!_isHovered && _isPressedWithLButton){
			_isPressedWithLButton = false;
			invokePressStateListeners(false,KEY_LBUTTON);
		}
	}

	void updateDraggingStates(){
		if(!isDragable || !isEnabled){
			_isDragging = false;
			_isDragPossible = false;
			return;
		}
		if(isHovered && _mouseLeftButtonPressed){
			_dragStartPosition = _mousePosition;
			_isDragPossible = true;
		}
		if(_isDragging && _dragCurrentPosition != _mousePosition){
			_dragCurrentPosition = _mousePosition;
			invokeDragEventListeners(DragMove,_dragCurrentPosition);
			dragLocation();
		}
		if(_isDragging && !_mouseLeftButtonHold){
			_isDragging = false;
			invokeDragEventListeners(DragFinished,_dragCurrentPosition);
			_isDragPossible = false;
		}
		if(_isDragPossible && !_mouseLeftButtonHold){
			_isDragPossible = false;
		}
		if(!_isDragging && _isDragPossible && (_dragStartPosition - _mousePosition).Length() > draggingThresold){
			_isDragging = true;
			_isDragPossible = false;
			_startPos = position;
			invokeDragEventListeners(DragStarted,_dragStartPosition);
		}
	}

	void dragLocation(){
		Vec2f movement;
		if(_dragCurrentPosition.x > _dragStartPosition.x){movement.x = _startPos.x + (_dragCurrentPosition.x - _dragStartPosition.x);}
		if(_dragCurrentPosition.x <= _dragStartPosition.x){movement.x = _startPos.x - (_dragStartPosition.x - _dragCurrentPosition.x);}
		if(_dragCurrentPosition.y > _dragStartPosition.y){movement.y = _startPos.y + (_dragCurrentPosition.y - _dragStartPosition.y);}
		if(_dragCurrentPosition.y <= _dragStartPosition.y){movement.y = _startPos.y - (_dragStartPosition.y - _dragCurrentPosition.y);}
		position = movement;
	}

	void updateClickStates(){
		_isClickedWithLButton = false;
		_isClickedWithRButton = false;
		if(_isPressedWithLButton && !_mouseLeftButtonHold && isHovered && !_isDragging){
			invokeClickListeners(_mousePosition.x,_mousePosition.y,KEY_LBUTTON);
			_isClickedWithLButton = true;
		}
		if(_isPressedWithRButton && !_mouseRightButtonHold && isHovered){
			invokeClickListeners(_mousePosition.x,_mousePosition.y,KEY_RBUTTON);
			_isClickedWithRButton = true;
		}
	}

	//Animation frame updating logic
	void updateAnimationState(){
		if(getGameTime() % _animFreq == 0)
		{
			_frame = _frame + 1;
			if (_frame >= _frameIndex.length) _frame=0;
		}
	}	

	//ToolTip
	void updateToolTipState()
	{
		if (_isHovered == true && toolTipTimer < toolTipDisp) {
			if(getGameTime() % getTicksASecond() == 0)
			{
				toolTipTimer++;
			}
		}
		if (toolTipTimer >= toolTipDisp){ dispToolTip();}
	}

	void setToolTip(string _tip, int _toolTipDisp, SColor _tipColor)
	{
		toolTip = _tip;
		toolTipDisp = _toolTipDisp; //Time (roughly in seconds) after item is hovered before tip displays 
		tipColor = _tipColor;
	}

	void dispToolTip()
	{
		Vec2f mouseScrPos= getControls().getMouseScreenPos()+Vec2f(18,18);
		drawRulesFont(toolTip,tipColor,mouseScrPos,mouseScrPos + Vec2f(20,15),false,true);
	}
	/* Serialization to CFG */
	/* 
		Those methods can be overriden to allow serialization of custom properties
		on custom items
	*/

	//Loading GUI position info from config
	void loadPos(const string modName,const f32 def_x,const f32 def_y)
	{
		if (getNet().isClient())
		{
			string configstr = "../Cache/"+modName+"_KGUI.cfg";
			ConfigFile cfg = ConfigFile( configstr );
			f32 x = cfg.read_f32(name+"_x",def_x);
			f32 y = cfg.read_f32(name+"_y",def_y);
			position = Vec2f(x,y);
		}
	}

	//Saving Gui position info to config
	void savePos(const string modName)
	{
		if (getNet().isClient())
		{
			print("save:" + name +" "+ modName);
			ConfigFile cfg = ConfigFile( "../Cache/"+modName+"_KGUI.cfg" );
			cfg.add_f32(name+"_x", position.x);
			cfg.add_f32(name+"_y", position.y);
			cfg.saveFile(modName+"_KGUI.cfg");
		}
	}

	//Getting Locked GUI info from config
	void getLocked(const string modName)
	{ 
		if (getNet().isClient())
		{
			string configstr = "../Cache/"+modName+"_KGUI.cfg";
			ConfigFile cfg = ConfigFile( configstr );
			bool _lock = cfg.read_bool("GUIlock", true);
			_isDragable = (_lock);
		}
		else {_isDragable = false;}
	}

	//Setting Locked GUI info to config
	void setLocked(const string modName,const bool lock)
	{
		if (getNet().isClient())
		{
			print ("SAVED GUIpos: "+lock);
			ConfigFile cfg = ConfigFile( "../Cache/"+modName+"_KGUI.cfg" );
			cfg.add_bool("GUIlock", lock);
			cfg.saveFile(modName+"_KGUI.cfg");
		}
	}

}

class Window : GenericGUIItem{
	

	//In constructor you can setup any additional inner UI elements
	Window(Vec2f _position,Vec2f _size){
		super(_position,_size);
	}

	Window(string _name, Vec2f _position,Vec2f _size){
		super(_position,_size);
		name = _name;
	}



	//Override this method to draw object. You can rely on position and size here.
	void drawSelf(){
		GUI::DrawWindow(position, position+size);
		GenericGUIItem::drawSelf();
	}

}

class Button : GenericGUIItem{
	string desc;
	SColor color;
	bool selfLabeled = false;
	bool toggled = false;

	Button(Vec2f _position,Vec2f _size){
		super(_position,_size);
	}

	//Use to automatically make a centered label on the button using text from _desc
	Button(Vec2f _position,Vec2f _size, string _desc, SColor _color){
		super(_position,_size);
		desc = _desc;
		color = _color;
		selfLabeled = true;
	}

	void drawSelf(){
		//Logic to change button based on state
		if(isClickedWithLButton || isClickedWithRButton || toggled){
			GUI::DrawButtonPressed(position, position+size);	
		} else if(isHovered){
			GUI::DrawButtonHover(position, position+size);
		} else {
			GUI::DrawButton(position, position+size);	
		}
		if (selfLabeled){
			drawRulesFont(desc,color,position + Vec2f(.5,.5),position + size - Vec2f(.5,.5),true,true);
		}
		GenericGUIItem::drawSelf();
	}

}

class ProgressBar : GenericGUIItem{
	
	float val;
	SColor color;
	bool colored = false;
	bool inversed = false;

	ProgressBar(Vec2f _position,Vec2f _size, float _initVal){
		super(_position,_size);
		val = _initVal;
	}

	ProgressBar(Vec2f _position,Vec2f _size, float _initVal, SColor _color, bool _inversed){
		super(_position,_size);
		val = _initVal;
		color = _color;
		colored = true;
		inversed = _inversed;
		// if inversed, bar fills from right to left, if not then fills normally (left to right)
	}

	void drawSelf(){
		if (colored){
			if (inversed){
				GUI::DrawRectangle(position, position+size);
				GUI::DrawRectangle((position+size)-Vec2f(size.x*val,size.y), position+size,color);
			}
			else{
				GUI::DrawRectangle(position, position+size);
				GUI::DrawRectangle(position, position+Vec2f(size.x*val,size.y),color);
			}
		}
		else GUI::DrawProgressBar(position, position+size, val);
		GenericGUIItem::drawSelf();
	}

	float findVal(int currentVal, int maxVal){
		return (1.0f*Maths::Abs(currentVal))/maxVal;
	}

	void setVal(float _val){
		val = _val;
	}

}

class Rectangle : GenericGUIItem{
	
	bool useColor = false;
	SColor color;

	Rectangle(Vec2f _position,Vec2f _size, SColor _color){
		super(_position,_size);
		color = _color;
		useColor = true;
	}

	Rectangle(Vec2f _position,Vec2f _size ){
		super(_position,_size);
	}

	void drawSelf(){
		if(useColor)
			GUI::DrawRectangle(position, position+size,color);
		else
			GUI::DrawRectangle(position, position+size);
		GenericGUIItem::drawSelf();
	}

}

class GUIContainer : GenericGUIItem{
	
	GUIContainer(){
		super(Vec2f(0,0),Vec2f(0,0));
	}

	void drawSelf(){
		GenericGUIItem::drawSelf();
	}

}



class Bubble : GenericGUIItem{
	
	Bubble(Vec2f _position,Vec2f _size){
		super(_position,_size);
	}

	void drawSelf(){
		GUI::DrawBubble(position, position+size);
		GenericGUIItem::drawSelf();
	}

}

class Line : GenericGUIItem{
	
	SColor color;

	Line(Vec2f _position,Vec2f _size, SColor _color){
		super(_position,_size);
		color = _color;
	}

	void drawSelf(){
		GUI::DrawLine2D(position, position+size, color);
		GenericGUIItem::drawSelf();
	}

}

class Label : GenericGUIItem{
	
	string label;
	SColor color;
	bool centered;
	Label(Vec2f _position,Vec2f _size,string _label,SColor _color,bool _centered){
		super(_position,_size);
		label = _label;
		color = _color;
		centered = _centered; //center text to middle of label
	}

	void drawSelf(){
		drawRulesFont(label,color,position,position+size,centered,centered);
		GenericGUIItem::drawSelf();
	}

	void setText(string _label){
		label = _label;
	}

}


class Icon : GenericGUIItem{
	
	string name;
	float scale;
	bool animate = false;

	//Static Icon setup
	Icon(Vec2f _position,Vec2f _size,string _name, float _scale = 1){
		super(_position,_size);
		name = _name;	
		scale = _scale;
	}

	//Animated Icon setup
	Icon(string image,Vec2f iDimension,int animFreq,Vec2f _position,Vec2f _size,string _name, float _scale = 1){
		super(_position,_size);
		_frame = 0;
		_animFreq = animFreq;
		_iDimension = iDimension;
		_image = image;
		name = _name;	
		scale = _scale;
		animate = true;
	}

	void addFrame(int frame){ //Add single frame
		_frameIndex.push_back(frame);
	}

	void addFrame(int[] frame){ //Add frames from an int[]
		for(int i = 0; i <frame.length; i++){
			_frameIndex.push_back(frame[i]);
		}

	}

	void addFrame(int start, int end){ //Add frames from a start to end
		for(int i = start; i < end; i++){
			_frameIndex.push_back(i);
		}

	}

	void drawSelf() override {
		if (animate){
			updateAnimationState();
			GUI::DrawIcon(_image,_frameIndex[_frame],_iDimension,position,scale );
		}
		else {
			GUI::DrawIconByName(name,position,scale);
			GenericGUIItem::drawSelf();
		}	
	}


}
