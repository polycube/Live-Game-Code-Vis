package  
{
	import flash.display.Shape;
	import flash.events.Event;
	import flash.display.DisplayObject;
	
	/**
	 * ...
	 * @author Anna Zajaczkowski
	 */
	public class Drop extends Shape
	{
		public function Drop(clr:uint) 
		{
			graphics.beginFill(clr, 1.0);
			graphics.drawRect( -0.5, -0.5, 1.0, 1.0);
			graphics.endFill();
			
			addEventListener(Event.ENTER_FRAME, update);
		}
		
		public function update(e:Event):void
		{
			this.alpha -= 0.05;
			this.scaleX += this.scaleX * Math.pow(this.alpha, 2.0) * 0.5;
			this.scaleY = this.scaleX;
			
			if (this.alpha <= 0) // explosion has faded
			{
				removeEventListener(Event.ENTER_FRAME, update);
				this.parent.removeChild(DisplayObject(this));
			}
		}
	}
	
}