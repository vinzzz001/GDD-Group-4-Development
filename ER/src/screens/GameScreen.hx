package screens;

import lime.ui.Mouse;
import openfl.Assets;
import openfl.events.Event;
import openfl.display.Sprite;
import openfl.Lib;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.text.TextFieldAutoSize;
//import src.*;
import sys.db.Sqlite;
import sys.db.Connection;
import sys.db.ResultSet;

/**
 * Simple screen in the application.
 * Shows a text, a button and a moving element.
 *
 */
class GameScreen extends Screen
{
	
	var patientDeck : Array<PatientCard> = [];
	var toolDeck : Array<ToolCard> = [];
	var staffDeck : Array<StaffCard> = [];

	var stCard : StaffCard;
	var pCard1 : PatientCard;

	var type : Array<String>;
	var value : Array<Int>;

	var pos : Int = 20;
	var pos2 : Int = 20;
	
	var players:Array<Player> = new Array<Player>();
	var cardsInHand:StaffCard;

	var patientsField : Array<PatientCard> = [];
	
	var currentTurn : Int = 1;
	
	private var _rect:Sprite;
	var allPromptButtons:Array<TextField>;
	var card:PatientCard;
	var staffValue:Int;
	var allTextField:openfl.text.TextField;
	
	public function new()
	{
		super();
	}

	override public function onLoad():Void
	{
		var toMenu:Button = new Button
		( 
			Assets.getBitmapData("img/Button.png"), 
			Assets.getBitmapData("img/Button_over.png"), 
			Assets.getBitmapData("img/Button_pressed.png"), 
			"quit", 
			onQuitClick 
		);
		
		toMenu.x = (stage.stageWidth-toMenu.width) / 2;
		toMenu.y = 100;
		addChild( toMenu );
		
		createStaff();
		readFromDataBase();
		
		shuffleDeck(patientDeck);
		shuffleDeck(staffDeck);
		
		createHand();
		displayPatients();
		displayTools();
		this.addEventListener(Event.ENTER_FRAME, canPlayerPlay);
		
	}
	
	function canPlayerPlay(e:Event)
	{
		for (player in players)
		{
			if (currentTurn == player.id)
			{
				player.turn = true;
			}
			else
			{
				player.turn = false;
			}
		}
	}
	
	function displayALLPrompt()
	{
		_rect = new Sprite();
		_rect.graphics.beginFill(0xFF0000);
		_rect.graphics.drawRect(0,0,400,300);
		_rect.graphics.endFill();
		
		_rect.x = 200;
		_rect.y = 100;
		
		addChild(_rect);
		
		var textFormat:TextFormat = new TextFormat("Verdana", 24, 0xbbbbbb, true);
		textFormat.align = TextFormatAlign.LEFT;
		
		allTextField = new TextField();
		allTextField.defaultTextFormat = textFormat;
		allTextField.autoSize = TextFieldAutoSize.LEFT;
		allTextField.text = "Who do you assign this to?";
		allTextField.x = _rect.width / 2 ;
		allTextField.y = _rect.y + 20;
		addChild(allTextField);
		
		allPromptButtons = new Array<TextField>();
		
		var iToString : String = "";
		
		for (i in 0...4)
		{
			
			switch (i) {
				case 0: iToString = "doctor";
				case 1: iToString = "nurse";
				case 2: iToString = "healthcare";
				case 3: iToString = "management";
			}
			
			//var promptButton:Button = new Button
			//( 
				//Assets.getBitmapData("img/Button.png"), 
				//Assets.getBitmapData("img/Button_over.png"), 
				//Assets.getBitmapData("img/Button_pressed.png"), 
				//iToString, 
				//promptButtonClicked
			//);
			
			var promptButton : TextField = new TextField();
			
			promptButton.defaultTextFormat = textFormat;
			promptButton.autoSize = TextFieldAutoSize.LEFT;
			promptButton.text = iToString;
			promptButton.x = _rect.width / 2 ;
			promptButton.y = _rect.y + 20;
			
			promptButton.addEventListener(MouseEvent.CLICK, promptButtonClicked);
			
			allPromptButtons.push(promptButton);
			promptButton.x = _rect.width - promptButton.width/2;
			promptButton.y = 200 + 50 * i;
			addChild(promptButton);
		}
	}
	
	function promptButtonClicked(e:MouseEvent)
	{
		var clickedButtonIndex:Int = allPromptButtons.indexOf(cast e.currentTarget);
		trace(clickedButtonIndex);
		trace(staffValue);
		
		switch(clickedButtonIndex){
			case 0: card.assignStaffCard("D", staffValue);
			case 1: card.assignStaffCard("N", staffValue); 
			case 2: card.assignStaffCard("H", staffValue); 
			case 3: card.assignStaffCard("M", staffValue);
		}
		removeALLPrompt();
	}
	
	function removeALLPrompt()
	{
		for (textField in allPromptButtons)
		{
			removeChild(textField);
		}
		removeChild(_rect);
		removeChild(allTextField);
	}
	
	private function patientClicked(e:Event):Void
	{
		trace("patient clicked");
		for (player in players)
		{
			if (player.turn)
			{
				card = cast (e.target);
				player.turn = false;
				currentTurn += 1;
				trace( currentTurn );
				
				if (currentTurn == 5)
				{
					currentTurn = 1;
				}
				
				var staffCard : StaffCard;
				
				if (player.selected.length == 1)
				{
					staffCard = player.selected.pop();
					player.removeCard(staffCard);
					var type : String = staffCard.type;
					staffValue = staffCard.num;
					
					card.assignStaffCard(type, staffValue);
					if (type == "ALL") displayALLPrompt();
				} 
			}
		}
	}
	
	private function toolClicked(e:Event):Void
	{
		trace("tool clicked");
		for (player in players)
		{
			if (player.turn)
			{
				var card : ToolCard = cast (e.target);
				player.turn = false;
				currentTurn += 1;
				trace( currentTurn );
				if (currentTurn == 5)
				{
					currentTurn = 1;
				}
				var staffCard : StaffCard;
				
				if (player.selected.length == 1)
				{
					staffCard = player.selected.pop();
					player.removeCard(staffCard);
					var type : String = staffCard.type;
					var value : Int = staffCard.num;
					
					card.assignStaffCard(type, value);
				} 
			}
		}
	}

	function displayTools()
	{
		var posX : Float = -toolDeck.length * toolDeck[0].width / 2;
		for (card in toolDeck)
		{
			card.addEventListener(MouseEvent.CLICK, toolClicked);
			addChild(card);
			card.x = 400 + posX;
			card.y = 150;
			posX += card.width + 10;
		}
		
	}
	
	function displayPatients()
	{
		
		for (i in 0...4)
		{
			
			var card = patientDeck.pop();
			patientsField.push(card);
		}
		var posX : Float = -patientsField.length * patientsField[0].width / 2;
		for (card in patientsField)
		{
			card.addEventListener(MouseEvent.CLICK, patientClicked);
			addChild(card);
			card.x = 400 + posX;
			card.y = 300;
			posX += card.width + 10;
		}
	}
	
	function createHand()
	{
		var card : StaffCard;
		
		for (i in 1...5)
		{
			var player = new Player(i);
			players.push(player);
			
			for (i in 0...4)
			{
				var card = staffDeck.pop();
				player.addCard(card);
			}
			addChild(player);
		}
	}
	
	function createStaff()
	{
		type = ["N", "D", "H", "M", "ALL"];
		value = [1, 2, 3, 4, 5];
		for (i in 0...2)
		{
			for (tp in type)
			{
				for (val in value) 
				{
					var imgname : String = "img/Staff_" + tp + "_" + val + ".png";
					stCard = new StaffCard(tp, val, imgname);
					staffDeck.push(stCard);
				}
			}
		}
		
		for (val in value)
		{
			var imgname : String = "img/Staff_" + "ALL" + "_" + val + ".png";
			stCard = new StaffCard("ALL", val, imgname);
			staffDeck.push(stCard);
		}
	}
	
	function shuffleDeck(deck : Dynamic)
	{
		var n:Int = deck.length;
		
		for (i in 0...n )
		{
			var change:Int = i + Math.floor( Math.random() * (n - i) );
			var tempCard = deck[i];
			deck[i] = deck[change];
			deck[change] = tempCard;
		}
	}

	function readFromDataBase()
	{
		// patients
		
		for (i in 1...16 )
		{
			var patientdat = Sqlite.open("db/patientdata.db");
			var resultset = patientdat.request("SELECT * FROM patients WHERE rowid = " + i + ";");

			for (row in resultset)
			{
				var patient : PatientCard = new PatientCard(row.imgID, row.doctor, row.nurse, row.management, row.healthcare, row.equipment, row.reward);
				patientDeck.push(patient);
			}
			
			if ( i == 16)
			{
				patientdat.close();
			}
		}

		// tools 

		for ( e in 1...6 )
		{
			var patientdat = Sqlite.open( "db/patientdata.db");
			var resultset = patientdat.request("SELECT * FROM tools WHERE rowid = " + e + ";");

			for (row in resultset)
			{
				var tool : ToolCard = new ToolCard(row.imgID, row.doctor, row.nurse, row.management, row.healthcare);
				toolDeck.push(tool);
			}

			if ( e == 6)
			{
				patientdat.close();
			}
		}

	}

	private function onQuitClick()
	{
		Main.instance.loadScreen( ScreenType.Menu );
	}

	override public function onDestroy()
	{
		
	}

}