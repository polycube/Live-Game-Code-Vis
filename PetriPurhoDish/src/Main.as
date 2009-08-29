package 
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLLoaderDataFormat;
	
	public class Main extends Sprite
	{
		private var fpsTimer:Timer = new Timer(1000);
		private var fps:Number = 0.0;
		private var frames:uint = 0;
		private var txtFPS:TextField;
		
		private var protos:Array = new Array();
		private var diatoms:Array = new Array();
		private var crashers:Array = new Array();
		
		private var loader:URLLoader;
		
		public function Main():void
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			var msk:Shape = new Shape();
			msk.graphics.beginFill(0xFFFFFF, 1.0);
			msk.graphics.drawCircle(0, 0, stage.stageHeight / 2);
			msk.graphics.endFill();
			msk.x = stage.stageWidth / 2;
			msk.y = stage.stageHeight / 2;
			this.mask = msk;
			
			var border:Shape = new Shape();
			border.graphics.beginFill(0x000000, 1.0);
			border.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			border.graphics.drawCircle(stage.stageWidth / 2, stage.stageHeight / 2, stage.stageHeight / 2);
			border.graphics.endFill();
			stage.addChild(border);
			
			txtFPS = new TextField();
			txtFPS.textColor = 0xFFFFFF;
			txtFPS.mouseEnabled = false;
			stage.addChild(txtFPS);
			
			fpsTimer.addEventListener(TimerEvent.TIMER, UpdateFPS);
			fpsTimer.start();
			
			//stage.addEventListener(MouseEvent.CLICK, mouseClick);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			//stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
			
			stage.addEventListener(Event.ENTER_FRAME, enterFrame);
			
			loader = new URLLoader();
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, loadComplete);
			
			loadFile();
		}
		
		private function loadFile():void
		{
			var request:URLRequest = new URLRequest("csv\\" + "2009-08-26.csv");
			loader.load(request);
			//fileNum++;
		}
		
		private function onIoError(e:IOErrorEvent):void
		{
			trace("io error");
		}
		
		private var data:String;
		
		private function loadComplete(e:Event):void
		{
			data = loader.data;
			
			//trace(data);
			
			//var myPattern:RegExp = /\r/g;
			var lines:Array = data.split('\n');
			//trace(lines[1]);
			
			for (var i:int = 0; i < lines.length; i++)
			{
				lines[i] = lines[i].split(',');
				trace(lines[i][0]);
			}
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
			
			updateProtos();
			
			stage.invalidate();
		}
		
		private function updateProtos():void
		{
			var distFromCenter:Point;
			var c:Crasher;
			
			var closestIndex:int = -1;
			var closestIndex2:int = -1;
			var closestDist:Number = -1.0;
			//var closestDist2:Number = -1.0;
			
			for (var i:int = 0; i < protos.length; i++)
			{
				closestIndex = -1;
				closestIndex2 = -1;
				closestDist = -1.0;
				//closestDist2 = -1.0;
				
				for (var j:int = 0/*i + 1*/; j < protos.length; j++)
				{
					var dist:Number = Math.pow(protos[i].posX - protos[j].posX, 2)
									+ Math.pow(protos[i].posY - protos[j].posY, 2);
					
					if ((dist < closestDist || closestIndex < 0 /*|| closestIndex2 < 0*/) && i != j)
					{
						closestIndex2 = closestIndex;
						//if (dist < closestDist)
						{
							closestDist = dist;
						}
						closestIndex = j;
					}
					
					if (i < protos.length - 1 && j > i) // do collision, don't check same two twice
					{
						var rad:Number = protos[i].creatureRadius * 2;// * 0.75;
						if (dist < rad * rad) // collision
						{
							var angle:Number = Math.atan2(protos[i].posY - protos[j].posY, protos[i].posX - protos[j].posX);
							protos[i].velX += Math.cos(angle) * (rad - Math.sqrt(dist)) * 0.1;
							protos[i].velY += Math.sin(angle) * (rad - Math.sqrt(dist)) * 0.1;
							protos[j].velX -= Math.cos(angle) * (rad - Math.sqrt(dist)) * 0.1;
							protos[j].velY -= Math.sin(angle) * (rad - Math.sqrt(dist)) * 0.1;
						}
					}
				}
				
				// modify vel to go towards closest
				var diff:Point;
				if (closestIndex > -1)
				{
					// get dist
					diff = new Point(protos[i].posX - protos[closestIndex].posX,
					                 protos[i].posY - protos[closestIndex].posY);
					if ((diff.x * diff.x) + (diff.y * diff.y) > Math.pow(protos[i].creatureRadius, 2))
					{
						protos[i].velX -= (protos[i].posX - protos[closestIndex].posX) * 0.01;
						protos[i].velY -= (protos[i].posY - protos[closestIndex].posY) * 0.01;
					}
				}
				/*if (closestIndex2 > -1)
				{
					diff = new Point(protos[i].posX - protos[closestIndex2].posX,
					                 protos[i].posY - protos[closestIndex2].posY);
					if ((diff.x * diff.x) + (diff.y * diff.y) > Math.pow(protos[i].creatureRadius, 2))
					{
						protos[i].velX -= (protos[i].posX - protos[closestIndex2].posX) * 0.01;
						protos[i].velY -= (protos[i].posY - protos[closestIndex2].posY) * 0.01;
					}
				}*/
				//trace(closestIndex + " : " + closestIndex2);
				
				protos[i].update(/*graphics*/);
				
				for each (c in crashers)
				{
					diff = new Point(protos[i].posX - c.posX,
					                 protos[i].posY - c.posY);
					
					if ((diff.x * diff.x) + (diff.y * diff.y) < (48 * 48) && c.attachment == null)
					{
						protos[i].attachCrasher(c);
					}
				}
				
				distFromCenter = new Point(
					protos[i].posX - (stage.stageWidth / 2),
					protos[i].posY - (stage.stageHeight / 2));
				
				if (distFromCenter.length > (stage.stageHeight / 2))
				{
					distFromCenter.normalize((stage.stageHeight / 2) /*- Creature.creatureRadius*/);
					protos[i].setPos(distFromCenter.x + (stage.stageWidth / 2),
									 distFromCenter.y + (stage.stageHeight / 2));
				}
			}
			
			for each (var d:Diatom in diatoms)
			{
				// test for collision with proto
				distFromCenter = new Point(
					d.posX - (stage.stageWidth / 2),
					d.posY - (stage.stageHeight / 2));
				
				if (distFromCenter.length > (stage.stageHeight / 2))
				{
					var oldVel:Point = new Point(
						d.posX - d.center.oldX, d.posY - d.center.oldY);
					
					distFromCenter.normalize((stage.stageHeight / 2) /*- Creature.creatureRadius*/);
					d.posX = distFromCenter.x + (stage.stageWidth / 2);
					d.posY = distFromCenter.y + (stage.stageHeight / 2);
					d.center.oldX = d.posX;
					d.center.oldY = d.posY;
					
					//Vect2 = Vect1 - 2 * WallN * (WallN DOT Vect1)
					distFromCenter.normalize(1.0);
					var dotProd:Number = distFromCenter.x * oldVel.x + distFromCenter.y * oldVel.y;
					var newVel:Point = new Point(d.velX - 2 * distFromCenter.x * dotProd,
												 d.velY - 2 * distFromCenter.y * dotProd);
					//trace(d.particle.velX);
					d.velX = newVel.x + oldVel.x;
					d.velY = newVel.y + oldVel.y;
				}
				
				d.update();
			}
			
			for each (c in crashers)
			{
				c.update();
			}
		}
		
		private function keyUp(e:KeyboardEvent):void
		{
			if (e.keyCode == 80) // P
			{
				protos.push(new Protozoan(mouseX, mouseY, stage));
				addChild(protos[protos.length - 1]);
				trace(protos.length);
			}
			else if (e.keyCode == 68) // D
			{
				diatoms.push(new Diatom(mouseX, mouseY, stage));
				addChild(diatoms[diatoms.length - 1]);
				trace(diatoms.length);
			}
			else if (e.keyCode == 67) // C
			{
				crashers.push(new Crasher(mouseX, mouseY, stage));
				addChild(crashers[crashers.length - 1]);
				trace(crashers.length);
			}
			//trace(e.keyCode);
		}
		
		private function mouseDown(e:MouseEvent):void
		{
			
		}
		
		private function mouseMove(e:MouseEvent):void
		{
		}
		
		private function mouseUp(e:MouseEvent):void
		{
		}
		
		/*if (protos[i].pos.x < 0) // && protos[i].vel.x < 0)
		{
			protos[i].pos.x = 0;
			//trace("beep");
		}
		else if (protos[i].pos.x > stage.stageWidth) // && protos[i].vel.x > 0)
		{
			protos[i].pos.x = stage.stageWidth;
		}
		
		if (protos[i].pos.y < 0) // && protos[i].vel.y < 0)
		{
			protos[i].pos.y = 0;
		}
		else if (protos[i].pos.y > stage.stageHeight) // && protos[i].vel.y > 0)
		{
			protos[i].pos.y = stage.stageHeight;
		}*/
	}
}