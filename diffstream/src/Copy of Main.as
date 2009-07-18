package 
{
	import flash.display.Sprite;
	import flash.events.Event;
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
			
			for (var i:uint = 0; i < lineLength.length; i++)
			{
				lineLength[i] = 0;
			}
			
			loader = new URLLoader();
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, loadComplete);
			
			timer.addEventListener(TimerEvent.TIMER, tick);
			//timer.start();
		}
		
		private function loadVarsComplete(e:Event):void
		{
			var loader:URLLoader = URLLoader(e.target);
			//trace(loader.data.insertedClr);
			insertClr = uint(loader.data.insertClr);
			deleteClr = uint(loader.data.deleteClr);
			equalClr = uint(loader.data.equalClr);
			
			timer.start();
		}
		
		private var fileNum:uint = 0;
		
		private function tick(e:TimerEvent):void
		{
			currentLine++;
			currentCol = 0;
			
			var request:URLRequest = new URLRequest("testcode\\test" + fileNum.toString() + ".txt");
			loader.load(request);
			fileNum++;
		}
		
		private function onIoError(e:IOErrorEvent):void
		{
			//trace("io error");
			timer.stop();
		}
		
		private var dataArray:Array;
		
		private var currentLine:uint = 0;
		private var currentCol:uint = 0;
		
		private var data1:String = null;
		private var data2:String = null;
		
		private var lineLength:Array = new Array(200);
		
		private var a:Number = 0.0;
		
		private function loadComplete(e:Event):void
		{
			//trace(loader.data);
			data1 = data2;
			data2 = loader.data;
			
			var diff:Array;
			
			if (data1 == null)
			{
				return;
			}
			else
			{
				//diff_match_patch differ = new diff_match_patch();
				diff = differ.diff_main(data1, data2);
				//differ.diff_cleanupSemantic(diff);
				differ.diff_cleanupEfficiency(diff);
			}
			
			var currentClr:uint = 0xE0E040;
			
			var chars:Array = new Array(); // array of lines (array of chars) (strings?)
			//var chars:Vector.<uint> = new Vector().<uint>;
			
			currentLine = 0;
			chars[currentLine] = new Array();
			currentCol = lineLength[0];
			
			a += 0.20;
			
			//if (fileNum == 8)
			//{
			graphics.beginFill(0x282828, 0.2);
			graphics.drawRect(0, 0, this.width, this.height);
			//}
			
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
				
				//var ar:Array = d.text.split('\n'); // ar is array of lines
				var s:String = "";
				
				//var myPattern:RegExp = /\s/g;
				
				//for each(var str:String in ar) // str is line of chunk
				//{
					/*var tempStr:String = str.replace(myPattern, "");
					if (tempStr == "{" || tempStr == "}" || tempStr == "")
					{
						str = "";
					}*/
				s = d.text; //str;
					//s = str.replace(myPattern, "");
					//s = str.replace(new RegExp(" ", "g"), "");
					//trace(str);
				
					//trace(s.length);
				for (var i:int = 0; i < s.length; i++)
				{
					if (currentCol > 80)
					{
						//currentCol = 0;
						//currentLine++;
					}
					
					var c:String = s.charAt(i);
					var code:Number = s.charCodeAt(i);
					if (code == 13) // carriage return
					{
						lineLength[currentLine] += 1;
						if (d.operation == Operation.DELETE)
						{
							lineLength[currentLine] = -1;
						}
						currentLine++;
						chars[currentLine] = new Array();
						while (lineLength[currentLine] == -1 && currentLine < lineLength.length)
						{
							currentLine++;
							chars[currentLine] = new Array();
						}
						currentCol = lineLength[currentLine]; //0;
					}
					else if (code == 10) // line feed
					{
					}
					else if (code == 9) // tab
					{
						/*currentCol += 4;
						lineLength[currentLine] += 4;*/
					}
					/*else if (c == " ") // || c == "{" || c == "}")
					{
						//trace(":|");
						//currentCol++;
					}*/
					else //if (s.length 
					{
						chars[currentLine].push(currentClr);
						
						// draw lines
						this.graphics.beginFill(currentClr, 1.0);
						this.graphics.drawRect(currentCol * 3, currentLine * 4, 3, 3);
						currentCol++;
						lineLength[currentLine]++;
					}
				}
				trace(chars[currentLine]);
			}
			//lineLength[0] += 64;
		}
		
		private function textChange(e:Event):void
		{
		}
		
		private function Update(/*e:Event*/):void
		{
		}
	}
}