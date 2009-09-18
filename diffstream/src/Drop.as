package  
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.display.LineScaleMode;
	import flash.text.TextFieldAutoSize;
	
	/**
	 * ...
	 * @author Anna Zajaczkowski
	 */
	public class Drop extends Sprite
	{
		public static var textSize:uint = 8;
		public static var font:String = "Lucida Console";
		//public static
		private var box:Shape = new Shape();
		
		public function Drop(clr:uint, char:String) 
		{
			box.graphics.beginFill(clr, 1.0);
			//graphics.drawRect( -0.5, -0.5, 1.0, 1.0);
			//graphics.lineStyle(1, clr, 1.0, false, LineScaleMode.NONE);
			box.graphics.drawRect( -0.5, -0.5, 1.0, 1.0);
			//graphics.drawRect( -1.0, -1.0, 2.0, 2.0);
			box.graphics.endFill();
			addChild(box);
			
			var textFormat:TextFormat = new TextFormat();
			textFormat.align = TextFormatAlign.CENTER;
			textFormat.font = "Lucida Console";
			textFormat.size = textSize;
			
			var txtChar:TextField = new TextField();
			txtChar.autoSize = TextFieldAutoSize.NONE;
			txtChar.textColor = /*0x282828;*/ clr;
			txtChar.text = char;
			txtChar.setTextFormat(textFormat);
			//txtChar.border = true;
			//txtChar.borderColor = 0xFFFF80;
			txtChar.height = 12;
			txtChar.width = 12;
			//txtChar.width = txtChar.textWidth;
			//txtChar.height = txtChar.textHeight;
			txtChar.scaleX = 0.1;
			txtChar.scaleY = 0.1;
			txtChar.x = -txtChar.width / 2;
			txtChar.y = -txtChar.height / 2;
			txtChar.mouseEnabled = false;
			
			addChild(txtChar);
			
			addEventListener(Event.ENTER_FRAME, update);
			
			//this.alpha = 0.5;
		}
		
		private var vel:Number = 0;
		
		public static var boxScaleSpeed:Number = 2.4;
		private var scaleSpeed:Number = boxScaleSpeed;
		public static var boxScaleAccel:Number = 0.2;
		public static var horizSpeedFactor:Number = 2.0;
		public static var boxAlphaFade:Number = 0.1;
		public static var boxAlphaFadeDrop:Number = 0.05;
		public static var gravity:Number = 0.25;
		private var hVel:Number = (Math.random() /*- 0.5*/) * horizSpeedFactor - 1.0;
		
		public function update(e:Event):void
		{
			/*this.alpha -= 0.05;
			this.scaleX += this.scaleX * Math.pow(this.alpha, 2.0) * 0.5;
			this.scaleY = this.scaleX;
			this.y += Math.pow(alpha, 2) * 4;
			
			if (this.alpha <= 0) // explosion has faded
			{
				removeEventListener(Event.ENTER_FRAME, update);
				this.parent.removeChild(DisplayObject(this));
			}*/
			
			//if (scaleX < 16)
			
			if (scaleSpeed > 0)
			{
				box.alpha -= boxAlphaFade;
				//scaleX += 0.5;
				scaleX += scaleSpeed;
				scaleY = scaleX;
				scaleSpeed -= boxScaleAccel;
			}
			else
			{
				vel += gravity;
				x += vel;
				y += hVel;
				if (box.alpha > 0)
				{
					box.alpha -= boxAlphaFadeDrop;
				}
			}
			
			if ((y * parent.scaleY > stage.stageHeight + 64)// && gravity > 0)
			 || (y * parent.scaleY < Main.initialHeight - stage.stageHeight -64) // && gravity < 0)
			 || (x * parent.scaleX > stage.stageWidth + 64)
			 || (x * parent.scaleX < -64))
			{
				//trace("bloop");
				removeEventListener(Event.ENTER_FRAME, update);
				this.parent.removeChild(DisplayObject(this));
			}
		}
	}
	
}