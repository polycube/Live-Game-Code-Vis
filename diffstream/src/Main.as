package 
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFieldType;
	import flash.events.TextEvent;
	import flash.net.URLLoaderDataFormat;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.display.StageScaleMode;
	import flash.events.IOErrorEvent;
	import name.fraser.neil.plaintext.diff_match_patch;
	import name.fraser.neil.plaintext.Diff;
	import name.fraser.neil.plaintext.Operation;
	//import flash.system.Security;
	
	public class Main extends Sprite
	{
		private var loader:URLLoader;
		private var txtTest:TextField = new TextField();
		private var timer:Timer = new Timer(1000);
		private var differ:diff_match_patch;
		
		private var insertClr:uint = 0x00FFFF;
		private var deleteClr:uint = 0xFF0000;
		private var equalClr:uint = 0xFFFFFF;
		
		private var chars:Array; /*= new Array();*/ // array of lines (array of chars) (strings?)
		
		private var lines:Array = new Array();
		
		public function Main():void
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			/*var textBox:TextField = new TextField();
			stage.addChild(textBox);
			textBox.textColor = 0xFFFF00;
			textBox.text = Security.sandboxType;
			trace(Security.sandboxType);*/
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			var settings:URLLoader = new URLLoader();
			settings.dataFormat = URLLoaderDataFormat.VARIABLES;
			settings.addEventListener(Event.COMPLETE, loadVarsComplete);
			settings.load(new URLRequest("settings.txt"));
			
			differ = new diff_match_patch;
			
			/*for (var i:uint = 0; i < lineLength.length; i++)
			{
				lineLength[i] = 0;
			}*/
			
			loader = new URLLoader();
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, loadComplete);
			
			timer.addEventListener(TimerEvent.TIMER, tick);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, timerComplete);
			
			stage.addEventListener(MouseEvent.CLICK, click);
			//timer.start();
		}
		
		private function click(e:MouseEvent):void
		{
			loadFile();
		}
		
		private function loadVarsComplete(e:Event):void
		{
			var loader:URLLoader = URLLoader(e.target);
			insertClr = uint(loader.data.insertClr);
			deleteClr = uint(loader.data.deleteClr);
			equalClr = uint(loader.data.equalClr);
		}
		
		private var fileNum:uint = 0;
		
		private function loadFile():void
		{
			var request:URLRequest = new URLRequest("testcode\\test" + fileNum.toString() + ".txt");
			loader.load(request);
			fileNum++;
		}
		
		private function onIoError(e:IOErrorEvent):void
		{
			trace("io error");
		}
		
		private var dataArray:Array;
		
		private var currentLine:uint = 0;
		private var currentCol:uint = 0;
		
		private var data1:String = null;
		private var data2:String = null;
		
		//private var lineLength:Array = new Array(200);
		
		private var a:Number = 0.0;
		
		private function loadComplete(e:Event):void
		{
			data1 = data2;
			data2 = loader.data;
			
			var diff:Array;
			
			if (data1 == null)
			{
				loadFile();
				return;
			}
			else
			{
				diff = differ.diff_main(data1, data2);
				//differ.diff_cleanupSemantic(diff);
				differ.diff_cleanupEfficiency(diff);
			}
			
			var currentClr:uint = 0xE0E040;
			
			currentLine = 0;
			chars = new Array(1); // 1);
			chars[currentLine] = new Array(); // 1);
			//chars[currentLine][0] = 0; //lineLength[currentLine];
			//currentCol = lineLength[0];
			
			a += 0.20;
			
			for each(var d:Diff in diff) // s is a diff chunk
			{
				if (d.operation == Operation.INSERT)
				{
					currentClr = insertClr; //0x40BFFF;
				}
				else if (d.operation == Operation.DELETE)
				{
					currentClr = deleteClr; //0xFF4060;
				}
				else if (d.operation == Operation.EQUAL)
				{
					currentClr = equalClr; //0xFFFFFF;
				}
				
				var s:String = "";
				
				s = d.text;
				
				var numInserted:uint = 0;
				var numDeleted:uint = 0;
				var numEqual:uint = 0;
				
				for (var i:int = 0; i < s.length; i++)
				{
					var code:Number = s.charCodeAt(i);
					if (code == 13) // carriage return
					{
						if (chars[currentLine].length > 0)
						{
						//lineLength[currentLine] += 1;
						//chars[currentLine].push(0x808080);
						/*if (d.operation == Operation.DELETE)
						{
							lineLength[currentLine] = Math.abs(lineLength[currentLine]) * -1;
						}*/
							/*if (numInserted > 0 && numEqual == 0 && numDeleted == 0)
							{
								chars[currentLine][0] = 1;
							}
							else if (numInserted == 0 && numEqual == 0 && numDeleted > 0)
							{
								chars[currentLine][0] = 2;
							}*/
							currentLine++;
							chars[currentLine] = new Array(); //1);
							//chars[currentLine][0] = 0;
							numInserted = 0;
							numDeleted = 0;
							numEqual = 0;
						//chars[currentLine][0] = lineLength[currentLine];
						/*while (lineLength[currentLine] < 0 && currentLine < lineLength.length)
						{
							currentLine++;
							chars[currentLine] = new Array();
							//chars[currentLine][0] = lineLength[currentLine];
						}*/
						}
						//currentCol = lineLength[currentLine]; //0;
					}
					else if (code == 10) // line feed
					{
						/*if (d.operation == Operation.INSERT)
						{
							lineLength.splice(currentLine, 0, 0);
							chars.splice(currentLine, 0, new Array(1));
							chars[currentLine][0] = 0; // lineLength[currentLine];
							currentLine++;
						}*/
					}
					else if (code == 9) // tab
					{
						/*currentCol += 4;
						lineLength[currentLine] += 4;*/
					}
					else if (code == 59)
					{
						
					}
					else //if (s.length 
					{
						chars[currentLine].push(currentClr);
						if (currentClr == insertClr)
						{
							numInserted++;
						}
						else if (currentClr == equalClr)
						{
							numEqual++;
						}
						else if (currentClr == deleteClr)
						{
							numDeleted++;
						}
						// draw lines
						/*this.graphics.beginFill(currentClr, 1.0);
						this.graphics.drawRect(currentCol * 3, currentLine * 4, 3, 3);
						currentCol++;*/
						//lineLength[currentLine]++;
					}
				}
			}
			
			//graphics.beginFill(0x282828, 0.2);
			//graphics.drawRect(0, 0, this.width, this.height);
			//graphics.endFill();
			
			//currentCol = 0;
			timer.reset();
			timer.repeatCount = 1;
			timer.delay = 125;
			timer.start();
			
			currentLine = 0;
			
			for (var l:int = 0; l < chars.length; l++)
			{
				numInserted = 0;
				numDeleted = 0;
				numEqual = 0;
				for (var j:int = 0; j < chars[l].length; j++)
				{
					if (chars[l][j] == insertClr)
					{
						numInserted++;
					}
					else if (chars[l][j] == equalClr)
					{
						numEqual++;
					}
					else if (chars[l][j] == deleteClr)
					{
						numDeleted++;
					}
				}
				
				if (currentLine > lines.length - 1)
				{
					//lines.push(new DiffLine()); // Shape());
					lines.splice(currentLine, 0, new DiffLine()); // Shape());
					stage.addChild(lines[currentLine]);
					lines[currentLine].y = currentLine * 3;
				}
				else if (chars[l][0] == insertClr && numInserted > numDeleted && numInserted > numEqual)// && chars[l][chars[l].length - 1] == insertClr)
				//&& (chars[l].length == 1 || chars[l][chars[l].length - 2] == insertClr))
				//else if (numInserted > 0 && numDeleted == 0 && numEqual == 0)
				{
					//l++;
					lines.splice(currentLine, 0, new DiffLine()); // Shape());
					stage.addChild(lines[currentLine]);
					lines[currentLine].y = currentLine * 3;
					//lineLength.splice(l, 0, 0);
					//lineLength[l] = 0;
					//trace(lineLength[l]);
				}
				
				while (lines[currentLine].inactive && currentLine < lines.length)
				{
					currentLine++;
					if (currentLine > lines.length - 1)
					{
						//lines.push(new DiffLine()); // Shape());
						lines.splice(currentLine, 0, new DiffLine()); // Shape());
						stage.addChild(lines[currentLine]);
					}
					lines[currentLine].y = currentLine * 3;
				}
				
				var lastClr:uint = 0;
				
				var shp:DiffLine = lines[currentLine];
				
				for (var j:int = 0; j < chars[l].length; j++)
				{
					shp.graphics.beginFill(chars[l][j], 1.0);
					shp.graphics.drawRect((lines[currentLine].lineLength) * 2, 0, 2, 2);
					//shp.graphics.drawRect((currentCol + j) * 1, 0, 1, 2);
					shp.graphics.endFill();
					shp.lineLength++;
					lastClr = chars[l][j];
				}
				
				if (chars[l][chars[l].length - 1] == deleteClr && numDeleted > numEqual && numDeleted > numInserted)
				/*chars[l][0] == deleteClr) // &&*/
				//&& (chars[l].length == 1 || chars[l][chars[l].length - 2] == deleteClr))
				//if (numInserted == 0 && numDeleted > 0 && numEqual == 0) //lastClr == deleteClr)
				{
					lines[currentLine].inactive = true;
					
					/*shp.graphics.beginFill(0x80FF80, 1.0);
					shp.graphics.drawRect((currentCol + j) * 2, 0, 2, 2);
					shp.graphics.endFill();*/
				}
				
				shp.lineLength++;
				
				lines[currentLine].y = currentLine * 3;
				currentLine++;
			}
			
			currentLine = 0;
			while (currentLine < lines.length)
			{
				/*if (lines[currentLine].lineLength == 0)
				{
					trace(currentLine);
				}*/
				lines[currentLine].y = currentLine * 3;
				currentLine++;
			}
			
			currentCol += 112;
			
			//trace("processing complete");
			
			//lineLength[0] += 48;
		}
		
		//private var currentCol:uint;
		
		private function tick(e:TimerEvent):void
		{

		}
		
		private function timerComplete(e:TimerEvent):void
		{
			//trace("timer complete");
			loadFile();
		}
	}
}