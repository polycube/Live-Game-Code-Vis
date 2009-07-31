package  
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Mouse;
	
	/**
	* ...
	* @author Anna Zajaczkowski
	*/
	public class Creature extends Shape
	{
		private var particles:Array;
		//private var constraints:Array;
		public var pos:Point;
		public var vel:Point;
		
		public function Creature(posX:Number, posY:Number, s:Stage) 
		{
			//graphics.lineStyle(2, 0x404040, 1.0);
			
			x = posX;
			y = posY;
			pos = new Point(posX, posY);
			vel = new Point(Math.random() - 0.5, Math.random() - 0.5);
			
			/*particles = new Array(8); // uint(Math.random() * 4 + 5));
			
			for (var i:uint = 0; i < particles.length; i++)
			{
				particles[i] = new Particle(48 * Math.cos(i * Math.PI / particles.length * 2) + pos.x,
				                            48 * Math.sin(i * Math.PI / particles.length * 2) + pos.y,
											0, 0, Math.random() * 16 + 4);
				s.addChild(particles[i]);
			}
			
			//addEventListener(Event.ENTER_FRAME, update);
			s.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			s.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			s.addEventListener(MouseEvent.MOUSE_UP, mouseUp);*/
			graphics.lineStyle(2, 0x404040, 1.0);
			graphics.drawCircle(0, 0, 32);
		}
		
		private var dragging:Boolean = false;
		
		private function mouseDown(e:MouseEvent):void
		{
			if (e.stageX > pos.x - 4 && e.stageX < pos.x + 4 && e.stageY > pos.y - 4 && e.stageY < pos.y + 4)
			{
				// start drag
				dragging = true;
			}
			//trace(e.localX);
		}
		
		private function mouseMove(e:MouseEvent):void
		{
			if (e.buttonDown && dragging)
			{
				/*pos.x = e.stageX;
				pos.y = e.stageY;*/
			}
		}
		
		private function mouseUp(e:MouseEvent):void
		{
			dragging = false;
		}
		
		public function update():void
		{
			pos.x += vel.x;
			pos.y += vel.y;
			x = pos.x;
			y = pos.y;
			
			if (vel.length > 2)
			{
				vel.x *= 0.8;
				vel.y *= 0.8;
			}
		}
		
		public function oldupdate(/*g:Graphics*//*e:Event*/):void
		{
			/*graphics.clear();
			var g:Graphics = graphics;
			g.beginFill(0x404040, 1.0);
			g.drawCircle(pos.x, pos.y, 2);
			g.endFill();
			
			g.lineStyle(2.0, 0x404040, 1.0);
			g.beginFill(0x404040, 0.5);
			g.moveTo(particles[particles.length - 1].x, particles[particles.length - 1].y);*/
			
			for (var i:uint = 0; i < particles.length; i++)
			{
				particles[i].posX -= (particles[i].posX - pos.x) * 0.02;
				particles[i].posY -= (particles[i].posY - pos.y) * 0.02;
				
				var nextP:uint = (i + 1) % particles.length;
				var delta:Point = new Point(particles[i].posX - particles[nextP].posX, particles[i].posY - particles[nextP].posY);
				
				var deltaLength:Number = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
				
				var diff:Number = (deltaLength - (particles[i].radius + particles[nextP].radius)) / deltaLength;
				
				//trace(particles[i].x);
				//trace(nextP + " : " + particles[nextP].x + ", " + delta + ", " + deltaLength + ", " + diff);

				particles[i].posX = particles[i].posX - (diff * 0.5 * delta.x);
				particles[i].posY = particles[i].posY - (diff * 0.5 * delta.y);
				particles[i].x = particles[i].posX;
				particles[i].y = particles[i].posY;
				
				particles[nextP].posX = particles[nextP].posX + (diff * 0.5 * delta.x);
				particles[nextP].posY = particles[nextP].posY + (diff * 0.5 * delta.y);
				
				
				nextP = (i + particles.length / 2) % particles.length;
				delta = new Point(particles[i].posX - particles[nextP].posX, particles[i].posY - particles[nextP].posY);
				
				deltaLength = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
				
				/*diff = (deltaLength - (particles[i].radius + particles[nextP].radius)) / deltaLength;
				
				if (deltaLength < particles[i].radius + particles[nextP].radius)
				{
					particles[i].x = particles[i].x - (diff * 0.5 * delta.x);
					particles[i].y = particles[i].y - (diff * 0.5 * delta.y);
					
					particles[nextP].x = particles[nextP].x + (diff * 0.5 * delta.x);
					particles[nextP].y = particles[nextP].y + (diff * 0.5 * delta.y);
				}*/
				if (deltaLength < particles[i].radius + particles[nextP].radius + 8)
				{
					//particles[i].x += (particles[i].x) * 0.2;
					//particles[i].y += (particles[i].y) * 0.2;
				}
				
				//if (i == 0)
				//{
					//trace(nextP + " : " + particles[nextP].x + ", " + delta + ", " + deltaLength + ", " + diff);
				//}
				
				/*g.lineStyle(2, 0x202020, 1.0);
				g.drawCircle(particles[i].x, particles[i].y, particles[i].radius);
				//graphics.drawCircle(particles[i].x, particles[i].y, 1);
				g.lineStyle(1, 0x202020, 1.0);
				g.moveTo(pos.x, pos.y);
				g.lineTo(particles[i].x, particles[i].y);*/
				
				//g.lineTo(particles[i].x, particles[i].y);
			}
			
			//g.endFill();
			
			//graphics.endFill();
		}
	}
	
}