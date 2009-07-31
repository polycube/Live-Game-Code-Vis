package 
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	public class Main extends Sprite
	{
		private var fpsTimer:Timer = new Timer(1000);
		private var fps:Number = 0.0;
		private var frames:uint = 0;
		private var txtFPS:TextField;
		
		private var creatures:Array = new Array();
		
		public function Main():void
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			//addChild(new Creature());
			txtFPS = new TextField();
			//txtFPS.x = 0;
			//txtFPS.y = 0;
			txtFPS.textColor = 0x000000;
			txtFPS.mouseEnabled = false;
			stage.addChild(txtFPS);
			
			fpsTimer.addEventListener(TimerEvent.TIMER, UpdateFPS);
			fpsTimer.start();
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseClick);
			//stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			stage.addEventListener(Event.ENTER_FRAME, enterFrame);
		}
		
		private function UpdateFPS(e:TimerEvent):void
		{
			fps = frames;
			txtFPS.text = fps.toString();
			frames = 0;
		}
		
		private function enterFrame(e:Event):void
		{
			frames++;
			
			//stage.graph
			/*graphics.clear();
			graphics.beginFill(0x747C70, 1.0);
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			graphics.endFill();*/
			for (var i:int = 0; i < creatures.length; i++)
			{
				if (i < creatures.length - 1)
				{
					for (var j:int = i + 1; j < creatures.length; j++)
					{
						var dist:Number = Math.pow(creatures[i].x - creatures[j].x, 2) + Math.pow(creatures[i].y - creatures[j].y, 2);
						if (dist < (66 * 66)) // collision
						{
							//trace(dist);
							var angle:Number = Math.atan2(creatures[i].y - creatures[j].y, creatures[i].x - creatures[j].x);
							//depth
							creatures[i].vel.x += Math.cos(angle) * (66 - Math.sqrt(dist)) * 0.5;
							creatures[i].vel.y += Math.sin(angle) * (66 - Math.sqrt(dist)) * 0.5;
							creatures[j].vel.x -= Math.cos(angle) * (66 - Math.sqrt(dist)) * 0.5;
							creatures[j].vel.y -= Math.sin(angle) * (66 - Math.sqrt(dist)) * 0.5;
						}
					}
				}
				if (creatures[i].pos.x < 0 && creatures[i].vel.x < 0)
				{
					creatures[i].vel.x *= -1;
				}
				else if (creatures[i].pos.x > stage.stageWidth && creatures[i].vel.x > 0)
				{
					creatures[i].vel.x *= -1;
				}
				if (creatures[i].pos.y < 0 && creatures[i].vel.y < 0)
				{
					creatures[i].vel.y *= -1;
				}
				else if (creatures[i].pos.y > stage.stageHeight && creatures[i].vel.y > 0)
				{
					creatures[i].vel.y *= -1;
				}
				creatures[i].update(/*graphics*/);
			}
		}
		
		private function mouseClick(e:MouseEvent):void
		{
			//trace("click");
			creatures.push(new Creature(mouseX, mouseY, stage));
			addChild(creatures[creatures.length - 1]);
		}
	}
}