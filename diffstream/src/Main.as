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
			loadFile();
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
		
		private var currentLine:uint = 0;
		private var currentCol:uint = 0;
		
		private var data1:String = null;
		private var data2:String = null;
		
		var linesRemaining:Array = new Array();
		
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
			var currentChars = new Array();
			
			var numInserted:uint = 0;
			var numDeleted:uint = 0;
			var numEqual:uint = 0;
			
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
				
				for (var i:int = 0; i < s.length; i++)
				{
					var code:Number = s.charCodeAt(i);
					if (code == 13) // carriage return
					{
						if (currentChars.length > 0)
						{
							if (currentLine > lines.length - 1) // new diff line
							{
								lines.splice(currentLine, 0, new DiffLine());
								stage.addChild(lines[currentLine]);
							}
							else if (currentChars[0] == insertClr
								&& numInserted > numDeleted && numInserted > numEqual) // inserted line
							{
								lines.splice(currentLine, 0, new DiffLine());
								stage.addChild(lines[currentLine]);
							}
							
							while (lines[currentLine].inactive && currentLine < lines.length) // skip inactive lines
							{
								currentLine++;
								if (currentLine > lines.length - 1)
								{
									lines.splice(currentLine, 0, new DiffLine());
									stage.addChild(lines[currentLine]);
								}
							}
							
							if (currentChars[currentChars.length - 1] == deleteClr &&
								numDeleted > numEqual && numDeleted > numInserted)
							{
								lines[currentLine].inactive = true;
							}
							
							lines[currentLine].chars = currentChars;
							lines[currentLine].addShape(new Shape());
							linesRemaining.push(lines[currentLine]);
							
							currentLine++;
						}
						currentChars = new Array();
						numInserted = 0;
						numDeleted = 0;
						numEqual = 0;
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
					else if (code == 59) // semicolon
					{
						
					}
					else //if (s.length 
					{
						currentChars.push(currentClr);
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
					}
				}
			}
			
			//currentCol = 0;
			
			currentLine = 0;
			
			var l:uint = 0;
			
			//var shp:Shape;
			
			for (l = 0; l < lines.length; l++)
			{
				lines[l].fade();
				lines[l].y = l * 2;
				
				//if (lines[l].chars != null && lines[l].chars.length > 0)
				//{
					//shp = new Shape();
					
					/*for (var j:int = 0; j < lines[l].chars.length; j++)
					{
						shp.graphics.beginFill(lines[l].chars[j], 1.0);
						shp.graphics.drawRect((lines[l].lineLength) * 1, 0, 1, 2);
						shp.graphics.endFill();
						lines[l].lineLength++;
					}*/
					
					//lines[l].addShape(shp);
					
					//linesRemaining.push(lines[l]);
					//trace(linesRemaining[linesRemaining.length - 1].chars == null);
				//}
				
				/*lines[l].lineLength++;
				lines[l].chars = null;*/
			}
			
			/*while (linesRemaining.length > 0)
			{
				l = Math.floor(Math.random() * linesRemaining.length);
				var diffLine:DiffLine = linesRemaining[l];
				
				if (diffLine.chars.length == 0) { continue; }
				var charClr:uint = diffLine.chars.shift();
				
				shp = diffLine.lastShape;
				
				shp.graphics.beginFill(charClr, 1.0);
				shp.graphics.drawRect((diffLine.lineLength) * 1, 0, 1, 2);
				shp.graphics.endFill();
				diffLine.lineLength++;
				
				if (diffLine.chars.length == 0)
				{
					diffLine.lineLength++;
					linesRemaining.splice(l, 1);
				}
			}*/
			
			currentLine = 0;
			
			currentCol += 104;
			
			timer.reset();
			timer.repeatCount = 0;
			timer.delay = 16;
			timer.start();
		}
		
		private var shp:Shape;
		
		private function tick(e:TimerEvent):void
		{
			var l:uint = Math.floor(Math.random() * linesRemaining.length);
			var diffLine:DiffLine = linesRemaining[l];
			
			//if (diffLine.chars.length == 0) { return; }
			var charClr:uint = diffLine.chars.shift();
			
			shp = diffLine.lastShape;
			
			shp.graphics.beginFill(charClr, 1.0);
			shp.graphics.drawRect((diffLine.lineLength) * 1, 0, 1, 1);
			shp.graphics.endFill();
			diffLine.lineLength++;
			
			var drop:Drop = new Drop(charClr);
			drop.x = (diffLine.lineLength) * 1;
			drop.y = diffLine.y;
			addChild(drop);
			
			if (diffLine.chars.length == 0)
			{
				diffLine.lineLength++;
				linesRemaining.splice(l, 1);
			}
			
			if (linesRemaining.length == 0)
			{
				timer.stop();
			}
		}
		
		private function timerComplete(e:TimerEvent):void
		{
			//trace("timer complete");
			//loadFile();
		}
	}
}