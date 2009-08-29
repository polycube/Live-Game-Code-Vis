package  
{
	import flash.display.Shape;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.display.Graphics;
	
	/**
	 * ...
	 * @author Anna Zajaczkowski
	 */
	public class Crasher extends Creature
	{
		private var particles:Array;
		//public var target:Point;
		
		public static var particleRadius:uint = 16;
		public static var creatureRad:uint = 32;
		public static var numParticles:uint = 4;
		
		private static var innerRadius:uint = 8;
		private static var outerRadius:uint = 24;
		private var particleDist:Number;
		private var particleDist2:Number;
		private var particleDist3:Number;
		private var particleDist4:Number;
		
		public var attachment:Particle = null;
		
		public function Crasher(X:Number, Y:Number, s:Stage) 
		{
			super(s);
			
			center = new Particle(X, Y, 0, 0, creatureRadius / 2, 0.99, 4.0);
			target = new Point(posX, posY);
			
			particles = new Array(numParticles); // uint(Math.random() * 4 + 5));
			
			for (var i:uint = 0; i < particles.length; i++)
			{
				var rad:Number = outerRadius;
				if (i % 2 == 0)
				{
					rad = innerRadius;
				}
				particles[i] = new Particle(rad * Math.cos(i * Math.PI / particles.length * 2) + posX,
				                            rad * Math.sin(i * Math.PI / particles.length * 2) + posY,
											0, 0, rad, 0.8, 8.0); // Math.random() * 16 + 4);
				//s.addChild(particles[i]);
			}
			
			particleDist = Math.sqrt(Math.pow(particles[0].posX - particles[1].posX, 2) + Math.pow(particles[0].posY - particles[1].posY, 2));
			particleDist2 = Math.sqrt(Math.pow(particles[0].posX - particles[2].posX, 2) + Math.pow(particles[0].posY - particles[2].posY, 2));
			particleDist3 = Math.sqrt(Math.pow(particles[1].posX - particles[3].posX, 2) + Math.pow(particles[1].posY - particles[3].posY, 2));
			particleDist4 = Math.sqrt(Math.pow(particles[0].posX - particles[(i + (particles.length / 2)) % particles.length].posX, 2) + Math.pow(particles[1].posY - particles[(i + (particles.length / 2)) % particles.length].posY, 2));
			
			//addEventListener(Event.ENTER_FRAME, update);
			/*s.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			s.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			s.addEventListener(MouseEvent.MOUSE_UP, mouseUp);*/
			addEventListener(Event.RENDER, render);
		}
		
		public override function get creatureRadius():Number
		{
			return 32;
		}
		
		private var dragging:Boolean = false;
		
		/*private function mouseDown(e:MouseEvent):void
		{
			if (e.stageX > posX - 8 && e.stageX < posX + 8 && e.stageY > posY - 8 && e.stageY < posY + 8)
			{
				dragging = true;
			}
		}
		
		private function mouseMove(e:MouseEvent):void
		{
			if (e.buttonDown && dragging)
			{
				target.x = e.stageX;
				target.y = e.stageY;
			}
		}
		
		private function mouseUp(e:MouseEvent):void
		{
			dragging = false;
		}*/
		
		public override function update():void
		{
			super.update();
			
			var nextP:uint;
			var delta:Point = new Point();
			var deltaLength:Number;
			var diff:Number;
			
			if (attachment != null)
			{
				delta = new Point(posX - attachment.posX, posY - attachment.posY);
				
				//deltaLength = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
				
				diff = 1.0; // (deltaLength - 0) / deltaLength;
				
				posX -= (diff * 0.2 * delta.x);
				posY -= (diff * 0.2 * delta.y);
				
				attachment.posX += (diff * 0.8 * delta.x);
				attachment.posY += (diff * 0.8 * delta.y);
			}
			
			for (var i:uint = 0; i < particles.length; i++)
			{
				// from center
				delta.x = particles[i].posX - center.posX;
				delta.y = particles[i].posY - center.posY;
				deltaLength = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
				
				/*if (deltaLength < 16)
				{
					diff = (deltaLength - 16) / deltaLength;
					
					particles[i].posX -= (diff * 1.0 * delta.x);
					particles[i].posY -= (diff * 1.0 * delta.y);
					
					//center.posX += (diff * 0.25 * delta.x);
					//center.posY += (diff * 0.25 * delta.y);
					
					//particles[i].posX -= (length - (creatureRadius * 0.5)) / length * 1.0 * (particles[i].posX - pos.x);
					//particles[i].posY -= (length - (creatureRadius * 0.5)) / length * 1.0 * (particles[i].posY - pos.y);
				}
				else*/
				//if (deltaLength > 32)
				{
					diff = (deltaLength - 24) / deltaLength;
					
					particles[i].posX -= (diff * 1.0 * delta.x);
					particles[i].posY -= (diff * 1.0 * delta.y);
					
					//center.posX += (diff * 0.25 * delta.x);
					//center.posY += (diff * 0.25 * delta.y);
					
					//particles[i].posX -= (length - (creatureRadius * 0.5)) / length * 1.0 * (particles[i].posX - pos.x);
					//particles[i].posY -= (length - (creatureRadius * 0.5)) / length * 1.0 * (particles[i].posY - pos.y);
				}
				
				for (var j:uint = 0; j < particles.length; j++)
				{
					delta.x = particles[i].posX - particles[j].posX;
					delta.y = particles[i].posY - particles[j].posY;
					deltaLength = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
					
					if (deltaLength < 4)
					{
						particles[i].velX += 0.05 * delta.x;
						particles[i].velY += 0.05 * delta.y;
					
						particles[j].velX -= 0.05 * delta.x;
						particles[j].velY -= 0.05 * delta.y;
					}
				}
				
				/*if (deltaLength > creatureRadius + 2)
				{
					//diff = (deltaLength - (creatureRadius * 0.5)) / deltaLength;
					particles[i].velX -= (particles[i].posX - posX) * 0.1;
					particles[i].velY -= (particles[i].posY - posY) * 0.1;
				}*/
				/*else if (deltaLength < creatureRadius - 2)
				{
					//diff = (deltaLength - (creatureRadius - 2)) / deltaLength;
					particles[i].velX += (particles[i].posX - posX) * 0.001;
					particles[i].velY += (particles[i].posY - posY) * 0.001;
				}*/
				
				particles[i].integrate();
			}
			
			center.integrate();
		}
		
		public /*override*/ function update2():void
		{
			super.update();
			
			var nextP:uint;
			var delta:Point = new Point();
			var deltaLength:Number;
			var diff:Number;
			
			delta = new Point(posX - attachment.posX, posY - attachment.posY);
			
			deltaLength = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
			
			diff = (deltaLength - 0) / deltaLength;
			
			posX -= (diff * 0.5 * delta.x);
			posY -= (diff * 0.5 * delta.y);
			
			attachment.posX += (diff * 0.5 * delta.x);
			attachment.posY += (diff * 0.5 * delta.y);
			
			for (var i:uint = 0; i < particles.length; i++)
			{
				var rad:Number;
				
				delta.x = particles[i].posX - posX;
				delta.y = particles[i].posY - posY;
				deltaLength = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
				
				/*if (i % 2 == 0)
				{
					rad = innerRadius;
					diff = (deltaLength - (rad)) / deltaLength;
					
					//if (deltaLength < rad)
					{
						particles[i].posX -= (diff * 1 * delta.x);
						particles[i].posY -= (diff * 1 * delta.y);
					}
					//if (deltaLength > rad + 2)
					//{
					//	particles[i].velX -= (particles[i].posX - posX) * 0.01;
					//	particles[i].velY -= (particles[i].posY - posY) * 0.01;
					//}
				}
				else
				{
					rad = outerRadius;
					
					diff = (deltaLength - (rad)) / deltaLength;
					
					particles[i].velX -= (diff * 1 * delta.x);
					particles[i].velY -= (diff * 1 * delta.y);
				}
				
				nextP = (i + 2) % particles.length;
				delta = new Point(particles[i].posX - particles[nextP].posX, particles[i].posY - particles[nextP].posY);
				
				deltaLength = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
				
				// skip one
				if (i % 2 == 0)
				{
					diff = (deltaLength - particleDist2) / deltaLength;
					
					//if (deltaLength < particleDist2)
					{
						particles[i].posX = particles[i].posX - (diff * 0.5 * delta.x);
						particles[i].posY = particles[i].posY - (diff * 0.5 * delta.y);
						
						particles[nextP].posX = particles[nextP].posX + (diff * 0.5 * delta.x);
						particles[nextP].posY = particles[nextP].posY + (diff * 0.5 * delta.y);
					}
				}*/
				
				particles[i].integrate();
			}
			
			center.integrate();
		}
		
		private function render(e:Event):void
		{
			var halfway:Point;
			
			graphics.clear();
			
			graphics.lineStyle(2.0, 0x404040, 1.0);
			graphics.beginFill(0x606060, 1.0);
			//graphics.moveTo(particles[particles.length - 1].posX, particles[particles.length - 1].posY);
			
			//graphics.moveTo(particles[i].posX, particles[i].posY);
			/*halfway = new Point(
				particles[particles.length - 1].posX + (particles[0].posX - particles[particles.length - 1].posX) / 2,
				particles[particles.length - 1].posY + (particles[0].posY - particles[particles.length - 1].posY) / 2);
			
			graphics.moveTo(halfway.x, halfway.y);*/
			
			for (var i:uint = 0; i < particles.length; i++)
			{
				//graphics.lineTo(particles[i].posX, particles[i].posY);
				/*halfway = new Point(
					particles[i].posX + (particles[(i + 1) % particles.length].posX - particles[i].posX) / 2,
					particles[i].posY + (particles[(i + 1) % particles.length].posY - particles[i].posY) / 2);
				
				graphics.curveTo(particles[i].posX, particles[i].posY, halfway.x, halfway.y);*/
				
				graphics.moveTo(center.posX, center.posY);
				graphics.lineTo(particles[i].posX, particles[i].posY);
			}
			
			graphics.endFill();
			
			graphics.lineStyle(0, 0, 0);
			graphics.beginFill(0x202020, 1.0);
			graphics.drawCircle(posX, posY, 2);
			graphics.endFill();
			
			graphics.lineStyle(2.0, 0x404040, 1.0);
			graphics.drawCircle(posX, posY, 8);
		}
	}
	
}