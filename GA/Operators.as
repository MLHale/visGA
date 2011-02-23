package GA
{
	public class Operators
	{
		private var ALPHA:Number = 0.01;
		private var BETA:Number = 0.1;
		public function Operators(){
		}
		public function calculate_fitness(ind:Individual):Number{
			count_total_distance(ind); 
			count_total_bends(ind);
			//trace("Total Distance = "+ind.total_distance+" Bends = " +ind.total_bends);
			ind.fitness = Math.round(ALPHA*ind.total_distance + BETA*ind.total_bends);
			return ind.fitness;
		}
		public function count_total_distance(ind:Individual):void{
			for(var i:Number =0; i<ind.length; i++){
				ind.total_distance += ind.getItemAt(i).distance;
			}
		}
		public function count_total_bends(ind:Individual):void{
			for(var i:Number =0; i<ind.length; i++){
				ind.total_distance += ind.getItemAt(i).bends;
			}
		}
	}
}