package GA
{
	import mx.collections.ArrayList;

	public class Individual extends ArrayList
	{
		public function Individual(){
			super();
		}
		public var fitness:Number = new Number();
		public var distance:Number = new Number();
		public var bends:Number = new Number();
		public var id:String = new String();
		public function increment_distance(dist:Number):void{
			distance +=dist;
		}
		public function increment_bends(bds:Number):void{
			bends += bds;
		}
	}
}