package  
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Anna Zajaczkowski
	 */
	public class DiffLine extends Sprite
	{
		public var lineLength:int = 0;
		public var inactive:Boolean = false;
		private var shapes:Array = new Array();
		public var chars:Array = null; // new Array();
		
		public static var minAlpha:Number = 0.4;
		public static var alphaFade:Number = 0.1;
		
		public var targetX:Number = -1;
		
		public function DiffLine() 
		{
			addEventListener(Event.ENTER_FRAME, update);
		}
		
		public function update(e:Event):void
		{
			if (targetX - x < 0.1)
			{
				x = targetX;
			}
			else
			{
				x += (targetX - x) * 0.1;
			}
		}
		
		public function addShape(shp:Shape):void
		{
			shapes.push(shp);
			this.addChild(shp);
		}
		
		/*public function get numShapes():uint
		{
			return shapes.length;
		}*/
		
		public function get lastShape():Shape
		{
			return shapes[shapes.length - 1];
		}
		
		public function fade():void
		{
			for each (var shp:Shape in shapes)
			{
				shp.alpha = Math.max(0.4, shp.alpha - 0.1);
			}
		}
	}
	
}