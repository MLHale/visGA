package GA
{
	import mx.collections.ArrayList;

	public class Individual extends ArrayList
	{
		public var fitness:Number;
		public var total_distance:Number;
		public var total_bends:Number;
		public var id:String;
		public function Individual(){
			super();
			fitness = 0;
			total_distance = 0;
			total_bends = 0;
			id = "";
		}
	}
}