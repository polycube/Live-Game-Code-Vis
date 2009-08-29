package  
{
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.display.Stage;
	import flash.display.Graphics;
	
	/**
	 * ...
	 * @author Anna Zajaczkowski
	 */
	public class Protozoan extends Creature
	{
		private var particles:Array;
		//public var pos:Point;
		//public var vel:Point;
		//public var target:Point;
		
		public static var particleRadius:uint = 8;
		public static var creatureRad:uint = 32;
		public static var numParticles:uint = 12;
		
		//public static var topSpeed:Number = 4.0;
		
		private var attached:Array = new Array();
		
		// track time of attraction/repulsion
		// track time of contact with other
		
		public function Protozoan(X:Number, Y:Number, s:Stage) 
		{
			super(s);
			//graphics.lineStyle(2, 0x404040, 1.0);
			
			//x = posX;
			//y = posY;
			//pos = new Point(X, Y);
			//vel = new Point(0, 0); //Math.random() - 0.5, Math.random() - 0.5);
			center = new Particle(X, Y, 0, 0, creatureRadius / 2, 0.99, 8.0);
			target = new Point(posX, posY);
			
			particles = new Array(numParticles); // uint(Math.random() * 4 + 5));
			
			for (var i:uint = 0; i < particles.length; i++)
			{
				particles[i] = new Particle(creatureRadius * Math.cos(i * Math.PI / particles.length * 2) + posX,
				                            creatureRadius * Math.sin(i * Math.PI / particles.length * 2) + posY,
											0, 0, particleRadius, 0.9, 8.0); // Math.random() * 16 + 4);
				//s.addChild(particles[i]);
			}
			
			//addEventListener(Event.ENTER_FRAME, update);
			addEventListener(Event.RENDER, render);
			//graphics.lineStyle(2, 0x404040, 1.0);
			//graphics.drawCircle(0, 0, 32);
		}
		
		public override function get creatureRadius():Number
		{
			return creatureRad;
		}
		
		public function attachCrasher(c:Crasher):void
		{
			for (var i:uint = 0; i < particles.length; i++)
			{
				if (particles[i].radius > 0)
				{
					var diff:Point = new Point(particles[i].posX - c.posX,
											   particles[i].posY - c.posY);
					
					if ((diff.x * diff.x) + (diff.y * diff.y) < (8 * 8))
					{
						c.attachment = particles[i];
						attached.push(c);
						particles[i].radius = -particles[i].radius;
						center.maxSpeed = Math.max(center.maxSpeed - 2.0, 0);
						this.alpha -= 0.2;
					}
				}
			}
			
			if (attached.length > 3)
			{
				
			}
		}
		
		public override function update():void
		{
			super.update();
			
			/*if (center.velocity.length > 4)
			{
				center.velocity.normalize(4);
			}*/
			
			/*posX += velX;
			posY += velY;
			velX *= 0.8;
			velY *= 0.8;*/
			
			for (var i:uint = 0; i < particles.length; i++)
			{
				var nextP:uint;
				var delta:Point = new Point();
				var deltaLength:Number;
				var diff:Number;
				
				// from center
				delta.x = particles[i].posX - center.posX;
				delta.y = particles[i].posY - center.posY;
				deltaLength = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
				if (deltaLength < creatureRadius * 0.75)
				{
					diff = (deltaLength - (creatureRadius * 0.75)) / deltaLength;
					
					particles[i].posX -= (diff * 0.75 * delta.x);
					particles[i].posY -= (diff * 0.75 * delta.y);
					
					center.posX += (diff * 0.25 * delta.x);
					center.posY += (diff * 0.25 * delta.y);
					
					//particles[i].posX -= (length - (creatureRadius * 0.5)) / length * 1.0 * (particles[i].posX - pos.x);
					//particles[i].posY -= (length - (creatureRadius * 0.5)) / length * 1.0 * (particles[i].posY - pos.y);
				}
				if (deltaLength < creatureRadius)
				{
					//particles[i].velX += center.velX;
					//particles[i].velY += center.velY;
				}
				
				if (deltaLength > creatureRadius + 2)
				{
					//diff = (deltaLength - (creatureRadius * 0.5)) / deltaLength;
					particles[i].velX -= (particles[i].posX - posX) * 0.001;
					particles[i].velY -= (particles[i].posY - posY) * 0.001;
				}
				else if (deltaLength < creatureRadius - 2)
				{
					//diff = (deltaLength - (creatureRadius - 2)) / deltaLength;
					particles[i].velX += (particles[i].posX - posX) * 0.001;
					particles[i].velY += (particles[i].posY - posY) * 0.001;
				}
				
				// particle chain
				nextP = (i + 1) % particles.length;
				delta = new Point(particles[i].posX - particles[nextP].posX, particles[i].posY - particles[nextP].posY);
				
				deltaLength = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
				
				//diff = (deltaLength - (particles[i].radius + particles[nextP].radius)) / deltaLength;
				diff = (deltaLength - (particleRadius * 2)) / deltaLength;
				
				particles[i].posX = particles[i].posX - (diff * 0.5 * delta.x);
				particles[i].posY = particles[i].posY - (diff * 0.5 * delta.y);
				
				particles[nextP].posX = particles[nextP].posX + (diff * 0.5 * delta.x);
				particles[nextP].posY = particles[nextP].posY + (diff * 0.5 * delta.y);
				
				// across
				nextP = (i + (particles.length / 2)) % particles.length;
				delta = new Point(particles[i].posX - particles[nextP].posX, particles[i].posY - particles[nextP].posY);
				
				deltaLength = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
				
				diff = (deltaLength - particleRadius * 3) / deltaLength;
				
				if (deltaLength < particleRadius * 3)
				{
					particles[i].posX = particles[i].posX - (diff * 0.5 * delta.x);
					particles[i].posY = particles[i].posY - (diff * 0.5 * delta.y);
					
					particles[nextP].posX = particles[nextP].posX + (diff * 0.5 * delta.x);
					particles[nextP].posY = particles[nextP].posY + (diff * 0.5 * delta.y);
				}
				
				/*if (deltaLength < particles[i].radius + particles[nextP].radius + 8)
				{
					//particles[i].posX += (particles[i].posX) * 0.2;
					//particles[i].posY += (particles[i].posY) * 0.2;
					//particles[nextP].posX -= (particles[nextP].posX) * 0.2;
					//particles[nextP].posY -= (particles[nextP].posY) * 0.2;
				}*/
				
				// skip one
				nextP = (i + 2) % particles.length;
				delta = new Point(particles[i].posX - particles[nextP].posX, particles[i].posY - particles[nextP].posY);
				
				deltaLength = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
				
				diff = (deltaLength - 16) / deltaLength;
				
				if (deltaLength < 16)
				{
					particles[i].posX = particles[i].posX - (diff * 0.5 * delta.x);
					particles[i].posY = particles[i].posY - (diff * 0.5 * delta.y);
					
					particles[nextP].posX = particles[nextP].posX + (diff * 0.5 * delta.x);
					particles[nextP].posY = particles[nextP].posY + (diff * 0.5 * delta.y);
				}
				
				// skip two
				nextP = (i + 3) % particles.length;
				delta = new Point(particles[i].posX - particles[nextP].posX, particles[i].posY - particles[nextP].posY);
				
				deltaLength = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
				
				diff = (deltaLength - particleRadius * 2) / deltaLength;
				
				if (deltaLength < particleRadius * 2)
				{
					particles[i].posX = particles[i].posX - (diff * 0.5 * delta.x);
					particles[i].posY = particles[i].posY - (diff * 0.5 * delta.y);
					
					particles[nextP].posX = particles[nextP].posX + (diff * 0.5 * delta.x);
					particles[nextP].posY = particles[nextP].posY + (diff * 0.5 * delta.y);
				}
				
				// skip three
				/*nextP = (i + 4) % particles.length;
				delta = new Point(particles[i].posX - particles[nextP].posX, particles[i].posY - particles[nextP].posY);
				
				deltaLength = Math.sqrt(delta.x * delta.x + delta.y * delta.y);
				
				diff = (deltaLength - particleRadius * 3) / deltaLength;
				
				if (deltaLength < particleRadius * 3)
				{
					particles[i].posX = particles[i].posX - (diff * 0.5 * delta.x);
					particles[i].posY = particles[i].posY - (diff * 0.5 * delta.y);
					
					particles[nextP].posX = particles[nextP].posX + (diff * 0.5 * delta.x);
					particles[nextP].posY = particles[nextP].posY + (diff * 0.5 * delta.y);
				}*/
				
				//particles[i].posX += particles[i].velX;
				//particles[i].posY += particles[i].velY;
				//particles[i].velX *= 0.9;
				//particles[i].velY *= 0.9;
				particles[i].integrate();
			}
			
			center.integrate();
		}
		
		private function render(e:Event):void
		{
			var halfway:Point;
			
			graphics.clear();
			//var g:Graphics = graphics;
			
			//graphics.lineStyle(2.0, 0x404040, 1.0);
			graphics.beginFill(0x606060, 1.0);
			//graphics.moveTo(particles[particles.length - 1].posX, particles[particles.length - 1].posY);
			
			/*if (i == 0)
			{*/
				//graphics.moveTo(particles[i].posX, particles[i].posY);
				//nextP = (particles.length);// % particles.length;
				halfway = new Point(
					particles[particles.length - 1].posX + (particles[0].posX - particles[particles.length - 1].posX) / 2,
					particles[particles.length - 1].posY + (particles[0].posY - particles[particles.length - 1].posY) / 2);
				
				graphics.moveTo(halfway.x, halfway.y);
			//}
			
			var i:int;
			
			for (i = 0; i < particles.length; i++)
			{
				//graphics.lineStyle(2.0, 0x404040, 1.0);
				if (i % 2 == 0)
				{
					//graphics.lineStyle(2.0, 0x000000, 1.0);
				}
				
				//graphics.lineTo(particles[i].posX, particles[i].posY);
				halfway = new Point(
					particles[i].posX + (particles[(i + 1) % particles.length].posX - particles[i].posX) / 2,
					particles[i].posY + (particles[(i + 1) % particles.length].posY - particles[i].posY) / 2);
				
				graphics.curveTo(particles[i].posX, particles[i].posY, halfway.x, halfway.y);
			}
			
			/*for (i = 0; i < particles.length; i++)
			{
				graphics.drawCircle(particles[i].posX, particles[i].posY, 2);
			}*/
			
			//graphics.lineTo(particles[0].posX, particles[0].posY);
			/*halfway = new Point(
				particles[0].posX + (particles[1].posX - particles[0].posX) / 2,
				particles[0].posY + (particles[1].posY - particles[0].posY) / 2);
			
			graphics.curveTo(particles[0].posX, particles[0].posY, halfway.x, halfway.y);*/
			
			graphics.endFill();
			
			//graphics.lineStyle(2.0, 0x404040, 1.0);
			graphics.lineStyle(2.0, 0x606060, 1.0);
			
			for (i = 0; i < particles.length; i++)
			{
				halfway = new Point(
					particles[i].posX + (particles[(i + 1) % particles.length].posX - particles[i].posX) / 2,
					particles[i].posY + (particles[(i + 1) % particles.length].posY - particles[i].posY) / 2);
				var nrm:Point = new Point(
					(particles[(i + 1) % particles.length].posY - particles[i].posY),
					-(particles[(i + 1) % particles.length].posX - particles[i].posX));
				nrm.normalize(4);
				graphics.moveTo(halfway.x, halfway.y);
				graphics.lineTo(halfway.x + nrm.x, halfway.y + nrm.y);
			}
			
			graphics.lineStyle(0, 0, 0);
			graphics.beginFill(0x202020, 1.0);
			graphics.drawCircle(posX, posY, 2);
			graphics.endFill();
		}
	}
}