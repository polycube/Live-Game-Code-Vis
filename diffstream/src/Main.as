package 
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.FileFilter;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.FileReference;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFieldType;
	import flash.events.TextEvent;
	import flash.net.URLLoaderDataFormat;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
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
		
		private var charWidth:uint = 3;
		private var charHeight:uint = 4;
		private var lineSpace:uint = 2;
		
		private var numCharsPerFrame:uint = 2;
		private var scale:Number = 1.0;
		
		private var fileNum:uint = 1;
		
		private var fr:FileReference;
		private var fileName1:String;
		private var fileName2:String;
		
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
			stage.align = StageAlign.BOTTOM_LEFT; // TOP_LEFT;
			
			var settings:URLLoader = new URLLoader();
			settings.dataFormat = URLLoaderDataFormat.VARIABLES;
			settings.addEventListener(Event.COMPLETE, loadVarsComplete);
			settings.load(new URLRequest("settings.txt"));
			
			fr = new FileReference();
			fr.addEventListener(Event.SELECT, openFile);
			fr.browse();
			
			differ = new diff_match_patch;
			
			/*for (var i:uint = 0; i < lineLength.length; i++)
			{
				lineLength[i] = 0;
			}*/
			
			loader = new URLLoader();
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, loadComplete);
			
			//timer.addEventListener(TimerEvent.TIMER, tick);
			//timer.addEventListener(TimerEvent.TIMER_COMPLETE, timerComplete);
			
			//stage.addEventListener(MouseEvent.CLICK, click);
			//timer.start();
			//loadFile();
		}
		
		private function openFile(e:Event):void
		{
			trace(fr.name);
			fileName1 = fr.name.substr(0, 10);
			fileName2 = fr.name.substr(13, 4);
			trace(fileName1 + "_##" + fileName2);
			
			loadFile();
		}
		
		public function zeroPad(number:int, width:int):String
		{
		   var ret:String = "" + number;
		   while (ret.length < width)
		   {
			   ret = "0" + ret;
		   }
		   return ret;
		}
		
		private function click(e:MouseEvent):void
		{
			//loadFile();
		}
		
		private function loadVarsComplete(e:Event):void
		{
			var loader:URLLoader = URLLoader(e.target);
			insertClr = uint(loader.data.insertClr);
			deleteClr = uint(loader.data.deleteClr);
			equalClr = uint(loader.data.equalClr);
			charWidth = uint(loader.data.charWidth);
			charHeight = uint(loader.data.charHeight);
			lineSpace = uint(loader.data.lineSpace);
			numCharsPerFrame = uint(loader.data.numCharsPerFrame);
			scale = Number(loader.data.scale);
			DiffLine.minAlpha = Number(loader.data.minAlpha);
			DiffLine.alphaFade = Number(loader.data.alphaFade);
			Drop.textSize = uint(loader.data.textSize);
			Drop.boxAlphaFade = Number(loader.data.boxAlphaFade);
			Drop.boxAlphaFadeDrop = Number(loader.data.boxAlphaFadeDrop);
			Drop.horizSpeedFactor = Number(loader.data.horizSpeedFactor);
			Drop.boxScaleSpeed = Number(loader.data.boxScaleSpeed);
			Drop.boxScaleAccel = Number(loader.data.boxScaleAccel);
			Drop.gravity = Number(loader.data.gravity);
			
			//trace(Drop.textSize);
			
			scaleX = scale;
			scaleY = scale;
			
			//y = stage.stageHeight;
		}
		
		private function loadFile():void
		{
			timer.removeEventListener(TimerEvent.TIMER_COMPLETE, loadFile);
			timer.stop();
			//var request:URLRequest = new URLRequest("testcode\\test" + fileNum.toString() + ".txt");
			var num:String = fileNum.toString();
			if (num.length < 2)
			{
				num = "0" + num;
			}
			var fullName:String = fileName1 + "\\" + fileName1 + "_" + num + "\\" + fileName1 + "_" + num + fileName2;
			trace(fullName);
			var request:URLRequest = new URLRequest(fullName);
			loader.load(request);
			fileNum++;
		}
		
		private function onIoError(e:IOErrorEvent):void
		{
			trace("io error");
		}
		
		private var currentLine:uint = 0;
		private var currentCol:uint = 0;
		
		private var data1:String = "";
		private var data2:String = "";
		
		private var linesRemaining:Array = new Array();
		
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
			var currentChars:Array = new Array();
			
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
					if (code == 10) // carriage return
					{
						if (currentChars.length > 0)
						{
							if (currentLine > lines.length - 1) // new diff line
							{
								lines.splice(currentLine, 0, new DiffLine());
								addChild(lines[currentLine]);
							}
							else if ((currentChars[0].clr == insertClr
								&& numInserted > numDeleted && numInserted > numEqual)
								|| (numInserted > 1  && numDeleted < 2 && numEqual < 2)) // inserted line
							{
								lines.splice(currentLine, 0, new DiffLine());
								addChild(lines[currentLine]);
							}
							
							while (lines[currentLine].inactive && currentLine < lines.length) // skip inactive lines
							{
								currentLine++;
								if (currentLine > lines.length - 1)
								{
									lines.splice(currentLine, 0, new DiffLine());
									addChild(lines[currentLine]);
								}
							}
							
							if (currentChars[currentChars.length - 1].clr == deleteClr &&
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
					else if (code == 13) // line feed
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
					/*else if (code == 59) // semicolon
					{
						
					}*/
					else //if (s.length 
					{
						currentChars.push(new CodeChar(currentClr, s.charAt(i)));
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
			
			currentLine = 0;
			
			var l:uint = 0;
			
			for (l = 0; l < lines.length; l++)
			{
				lines[l].fade();
				if (lines[l].targetX == -1)
				{
					lines[l].x = l * (lineSpace + charHeight);
				}
				lines[l].targetX = l * (lineSpace + charHeight);
			}
			
			currentLine = 0;
			
			currentCol += 104;
			
			/*timer.reset();
			timer.repeatCount = 0;
			timer.delay = 17;
			timer.start();*/
			addEventListener(Event.ENTER_FRAME, tick);
		}
		
		private var shp:Shape;
		
		private function tick(e:Event):void
		{
			for (var i:uint = 0; i < numCharsPerFrame - 1; i++)
			{
				appendChar();
			}
		}
		
		private function appendChar():void
		{
			var l:uint = Math.floor(Math.random() * linesRemaining.length);
			var diffLine:DiffLine = linesRemaining[l];
			
			if (diffLine == null) { /*trace("pooop");*/ return; }
			var codeChar:CodeChar = diffLine.chars.shift();
			
			var pos = stage.stageHeight - (diffLine.lineLength) * charWidth;
			
			shp = diffLine.lastShape;
			
			shp.graphics.beginFill(codeChar.clr, 1.0);
			//shp.graphics.drawRect(0, (diffLine.lineLength) * charWidth, charHeight, charWidth);
			shp.graphics.drawRect(0, pos, charHeight, charWidth);
			shp.graphics.endFill();
			diffLine.lineLength++;
			
			var drop:Drop = new Drop(codeChar.clr, codeChar.char);
			drop.y = pos + (charWidth / 2);
			drop.x = diffLine.x + (charHeight / 2);
			addChild(drop);
			
			if (diffLine.chars.length == 0)
			{
				diffLine.lineLength++;
				linesRemaining.splice(l, 1);
			}
			
			if (linesRemaining.length == 0)
			{
				removeEventListener(Event.ENTER_FRAME, tick);
				//timer.stop();
				timer.reset();
				timer.addEventListener(TimerEvent.TIMER, startLoad);
				timer.repeatCount = 0;
				timer.delay = 3000;
				timer.start();
				//loadFile();
			}
		}
		
		private function startLoad(e:TimerEvent):void
		{
			loadFile();
		}
		
		private function timerComplete(e:TimerEvent):void
		{
			//trace("timer complete");
			//loadFile();
		}
	}
}