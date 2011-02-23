package GA
{
	import flash.display.Sprite;
	import flash.geom.Point;
	public class Line extends Point
	{
		public var bends:Number;
		//commands 1 = moveTo(), 2 = lineTo()
		public var commands:Vector.<int>;
		public var coords:Vector.<Number>;
		public var distance:Number;
		public function Line()
		{
			super();
			bends = 0;
			commands = new Vector.<int>();
			coords = new Vector.<Number>();
			distance = 0;
		}
		public function increment_distance(dist:Number):void{
			distance +=dist;
		}
		public function increment_bends(bds:Number):void{
			bends += bds;
		}
		
	}
}