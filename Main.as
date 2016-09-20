
import GA.*;

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Point;
import flash.utils.*;

import mx.collections.ArrayList;
import mx.controls.Text;
import mx.core.Container;
import mx.core.UIComponent;

import spark.effects.Animate;
import spark.effects.animation.Animation;
import spark.events.TextOperationEvent;

protected var mutation_rate:Number = 0.05;
protected var start_pts_param:int = 10;
protected var start_pts_param_max:int = 100;
protected var end_pts_param:int = start_pts_param;
protected var end_pts_param_max:int = 100;
protected var obstacles_param:int = 10;
protected var obstacles_param_max:int = 100;
protected var max_obstacle_height:Number = 80;
protected var max_obstacle_width:Number = 80;

//contains a set of Individuals
protected var population:ArrayList = new ArrayList();
protected var max_pop:Number = 20;

//Graphics objects
protected var obstacles:Array = new Array();
protected var start_pts:Array = new Array();
protected var end_pts:Array = new Array();

//UI variables
protected var console:Boolean = true;
protected var debug:Boolean = false;
protected var graphics_xmin:int,graphics_xmax:int;
protected var graphics_ymin:int,graphics_ymax:int;
// containers( IVisualElements ) for DisplayObjects of each type
protected var obstacle_container:UIComponent = new UIComponent();
protected var start_pt_container:UIComponent = new UIComponent();
protected var end_pt_container:UIComponent = new UIComponent();
protected var line_container:UIComponent = new UIComponent();


//Called when flex is finished loading the swf
protected function init():void{
	p("Starting the Visual GA application");
	input_start_pts.text = str(start_pts_param);
	input_end_pts.text = str(end_pts_param);
	input_obstacles.text = str(obstacles_param);
	input_mutation_rate.text = str(mutation_rate);
	//border.visible = debug;
	console_group.visible = console;
	console_group.enabled = console;
	graphics_xmax = rendering_area.x + rendering_area.width;
	graphics_ymax = rendering_area.y + rendering_area.height;
	graphics_xmin = rendering_area.x;
	graphics_ymin = rendering_area.y;
	p("(x,y),(x_max,y_max) - ("+rendering_area.x+","+rendering_area.y+") ("+graphics_xmax+","+graphics_ymax+")");

	this.addElement(obstacle_container);
	this.addElement(start_pt_container);
	this.addElement(end_pt_container);
	this.addElement(line_container);
	obstacle_container.cachePolicy="auto";
	start_pt_container.cachePolicy = "auto";
	end_pt_container.cachePolicy = "auto"
	console_pane.cachePolicy = "auto";
	this.addEventListener(Event.ENTER_FRAME,main_loop);

}

/* helper functions */
protected function p(text:String):void{
	//console_pane.text += this+">"+text+"\n";
	
	//console_pane.scrollToRange(console_pane.text.length,console_pane.text.length);
	//console_pane.validateNow();
}
protected function update_completed():void{
	trace("++++Update completed++++");
}
protected function fit_p(text:String):void{
	population_pane.appendText(text+"\n");
}
protected function status(text:String):void{
	status_box.text = text;
	fader.target = status_box;
	fader.play();	
}
protected function random(max:Number,...min):Number{
	if (min[0] > 0){
		return Math.round(Math.random() * (max - min[0])) + min[0];
	}
	else{
		return Math.round(Math.random()*max);
	}
}
protected function str(var_name:Object):String{
	return String(var_name);
}
protected function random_x():Number{
	return random(rendering_area.width) + rendering_area.x;
}
protected function random_y():Number{
	return random(rendering_area.height) + rendering_area.y;
}

/* UI Handlers */
protected function start_pts_changeHandler(event:TextOperationEvent):void{
	start_pts_param = int(input_start_pts.text);
	if (start_pts_param<=start_pts_param_max){					
		p("start_pts_param set to: "+start_pts_param);
	}
	else{
		input_start_pts.text = str(start_pts_param_max);
		start_pts_param = start_pts_param_max;
		p("Invalid value, start_pts_param set to start_pts_param_max: "+start_pts_param_max);
	}
	end_pts_param = int(input_start_pts.text);
	if (end_pts_param<=end_pts_param_max){
		input_end_pts.text = str(end_pts_param);
		p("end_pts_param set to: "+end_pts_param);
	}
	else{
		input_end_pts.text = str(end_pts_param_max);
		end_pts_param = end_pts_param_max;
		p("Invalid value, end_pts_param set to end_pts_param_max: "+end_pts_param_max);
	}
}

protected function end_pts_changeHandler(event:TextOperationEvent):void{
	end_pts_param = int(input_end_pts.text);
	if (end_pts_param<=end_pts_param_max){
		p("end_pts_param set to: "+end_pts_param);
	}
	else{
		input_end_pts.text = str(end_pts_param_max);
		end_pts_param = end_pts_param_max;
		p("Invalid value, end_pts_param set to end_pts_param_max: "+end_pts_param_max);
	}
	start_pts_param = int(input_end_pts.text);
	if (start_pts_param<=start_pts_param_max){
		input_start_pts.text = str(start_pts_param);
		p("start_pts_param set to: "+start_pts_param);
	}
	else{
		input_start_pts.text = str(start_pts_param_max);
		start_pts_param = start_pts_param_max;
		p("Invalid value, start_pts_param set to start_pts_param_max: "+start_pts_param_max);
	}
}


protected function obstacles_changeHandler(event:TextOperationEvent):void{
	obstacles_param = int(input_obstacles.text);
	if (obstacles_param<=obstacles_param_max){
		p("obstacles_param set to: "+obstacles_param);
	}
	else{
		input_obstacles.text = str(obstacles_param_max);
		obstacles_param = obstacles_param_max;
		p("Invalid value, obstacles_param set to obstacles_param_max: "+obstacles_param_max);
	}
}
protected function mutation_rate_changeHandler(event:TextOperationEvent):void{
	mutation_rate = int(input_mutation_rate.text);
	if (0<=mutation_rate<=100){
		p("mutation_rate set to: "+mutation_rate);
	}
	else if (mutation_rate < 0){
		mutation_rate = 0;
		p("Invalid value, mutation_rate set to: 0");
	}
	else if (mutation_rate > 100){
		mutation_rate = 100;
		p("Invaled value, mutation_rate set to: 100");
	}
}

/* GA Functions */
protected function main_loop(evt:Event):void{
	if(started){
		if(obstacles_placed){
			//run in parallel 
			place_start_pts();
			place_end_pts();
		}
		if(obstacles_placed && start_pts_placed && end_pts_placed){
			//GA is setup...begin simulation (event driven)
			if(!processing_population){
				//calculate a population
				if(generation>0){
					//this will be changed to genetic algorithm code
					status("Cleaning up...");
					population_pane.text = "";
					member = new Individual();
					population.removeAll();
					System.gc();
				}
				this.callLater(generate_population,[]);
			}
		}
	}
	gen_box.text = str(generation);
}
protected var started:Boolean = false;
protected var isPaused:Boolean = false;
protected var generation:Number=0;
protected var best_so_far:Number = Infinity;
protected function setup_ga():void{
	if(!started){
		started = true;
		p("Setting up environment...");
		status("Setting up environment");
		place_obstacles();
		start_btn.label = "Pause";
	}
	else{//pause / resume toggle
		if(!isPaused){
			isPaused = true;
			start_btn.label = "Resume";
		}
		else{
			isPaused = false;
			start_btn.label = "Pause";
			this.callLater(generate_population,[]);//this may need to change depending on the flow of code execution
		}
	}
	
}


protected var processing_population:Boolean = false;
protected var processing_individual:Boolean = false;
protected var member:Individual = new Individual();
protected var ga_operators:Operators = new Operators();
protected function generate_population():void{
	//p("Current member.length"+str(member.length));
	if(!isPaused){
		if(!processing_individual && population.length < max_pop){
			processing_population = true;
			
			if(member.length == start_pts.length){
				//only add fully completed arrays
				if(debug){trace("member completed...calculating fitness");}
				status("Calculating fitness...");
				ga_operators.calculate_fitness(member);
				fit_p("#"+member.id + " -  "+str(member.fitness));
				p("Fitness for "+member.id+" is "+ str(member.fitness));

				population.addItem(member);
				
				//clear current lines
				if(debug){trace("Number of children to remove: "+line_container.numChildren);}
				best_so_far = ga_operators.best_so_far(member.fitness,best_so_far);
				best_box.text = "Best - "+str(best_so_far);
				this.removeElement(line_container);
				line_container = new UIComponent();
				this.addElement(line_container);

			}
			//new member
			member = new Individual();
			member.id = str(population.length);

			p("Creating individual...");
			status("Creating individual...");
			if(debug){trace("Calling create_individual (from pop) ");}
			this.callLater(create_individual,[]);
		}
		else if(processing_individual && population.length < max_pop){
			//currently processing individual just wait
			this.callLater(generate_population,[])
		}
		else{
			//population is > max_pop = > done processing for now
			processing_population = false;
			//for debug only!!!! - just to get the first generation and stop
			//processing_population = true;
			generation++;//will cause mutation and crossover to occur
		}
	}
}
protected function create_individual(curr_line:Number=0):void{
	processing_individual = true;
	var new_line_sprite:Sprite = new Sprite();
	var new_line:Line = new Line();
	
	//Points to connect
	var from:Point = new Point(start_pts[curr_line].x,start_pts[curr_line].y);
	var to:Point = new Point(end_pts[curr_line].x,end_pts[curr_line].y);
	// display_object goes to container
	line_container.addChild(new_line_sprite);

	//generate random x, y path between from and to
	var curr_pt:Point = random_point(from,to);
	new_line.commands.push(1,2);
	new_line.coords.push(from.x,from.y,curr_pt.x,curr_pt.y);
	while((curr_pt.x != to.x) || (curr_pt.y != to.y)){
		if(debug){p("Curr PT: "+curr_pt.toString());}
		curr_pt = random_point(curr_pt,to);
		new_line.commands.push(2);
		new_line.coords.push(curr_pt.x,curr_pt.y);
		new_line.increment_distance(distance(from.x,from.y,to.x,to.y));
		//p("Line distance = "+str(new_line.distance));
	}
	if(debug){p("From PT: "+from.toString() +" To PT: "+to.toString());}

	//calculate bends
	new_line.bends=new_line.coords.length/2 - 1;
	p("Created line: "+new_line.coords.toString());
	
	//set line style (thickness, color)
	new_line_sprite.graphics.lineStyle(1,0x000000)
	new_line_sprite.graphics.drawPath(new_line.commands,new_line.coords);
	
	//increment the Individual's total distance
	member.addItem(new_line);

	//recursion
	curr_line++;
	if(curr_line < start_pts.length){
		this.callLater(create_individual,[curr_line]);
		status("Calculating lines...");
	}
	else{
		processing_individual = false;
		status("Calculating lines...DONE");
		if(debug){trace("Calling generate_pop() curr_line="+curr_line);}
		
		this.callLater(generate_population,[])
	}
}
protected function distance(x1:Number,y1:Number,x2:Number,y2:Number):Number{
	return Math.sqrt((Math.pow((x1 - x2),2) + Math.pow((y1 - y2),2))); 
}
protected var jump_dist:Number = 50;
protected var opposite_dir:Number = 5;
protected var probability_of_opposite:Number = 15;
protected function random_point(from:Point,to:Point):Point{
	var r_point:Point = new Point();
	
	if(debug){p("Need to go in direction: "+direction_x+" , "+ direction_y);}
	var axis:Number = random(1);
	var direction:Number = random(99); //90% chance to go towards to.x 10% to go opposite way
	if(debug){p("Axis: "+str(axis)+", Direction: "+str(direction));}
	if(axis==0){
		var direction_x:String = "";
		if (from.x > to.x){
			//go east
			direction_x="W";
		}
		else{
			direction_x="E";
		}
		//move along x
		var x_dist:Number = distance(from.x,0,to.x,0);
		if(debug){p("X_distance: "+str(x_dist));}
		if(direction_x=="W" && direction>(probability_of_opposite-1)){
			if(debug){p("Going W");}
			if(x_dist < jump_dist){
				r_point.x = to.x;// same as from.x - dist_x
			}
			else{
				r_point.x = from.x - random(x_dist);
			}
			if(r_point.x < graphics_xmin){
				r_point.x = graphics_xmin;
			}
		}
		else if(direction_x=="W" && direction<=(probability_of_opposite-1)){
			if(debug){p("Going E");}
			//go east even though to.x is to the west - to get over local obstacles (similar to hill climbing)
			r_point.x = from.x + random(x_dist/opposite_dir);
			if(r_point.x > graphics_xmax){
				r_point.x = graphics_xmax;
			}
		}
		else if(direction_x=="E" && direction>(probability_of_opposite-1)){
			if(debug){p("Going E");}
			if(x_dist < jump_dist){
				r_point.x = to.x;// same as from.x + dist_x
			}
			else{
				r_point.x = from.x + random(x_dist);
			}
		}
		else if(direction_x=="E" && direction<=(probability_of_opposite-1)){
			if(debug){p("Going W");}
			//go west even though to.x is to the east - to get over local obstacles (similar to hill climbing)
			r_point.x = from.x - random(x_dist/opposite_dir);
		}
		//check bounds of x
		if(r_point.x > graphics_xmax){//E
			r_point.x = graphics_xmax;
		}
		else if(r_point.x < graphics_xmin){//W
			r_point.x = graphics_xmin;
		}
		r_point.y = from.y;
		if(debug){p("coords (from x): "+r_point.x+", "+r_point.y);}
	}
	else if(axis==1){
		var direction_y:String = "";
		if(from.y > to.y){
			//go North
			direction_y="N";
		}
		else{
			direction_y="S";
		}
		//move along y
		var y_dist:Number = distance(0,from.y,0,to.y);
		if(debug){p("y_distance: "+str(y_dist));}
		if(direction_y=="N" && direction>(probability_of_opposite-1)){
			if(debug){p("Going N");}
			if(y_dist < jump_dist){
				r_point.y = to.y;// same as from.y - dist_y
			}
			else{
				r_point.y = from.y - random(y_dist);
			}
		}
		else if(direction_y=="N" && direction<=(probability_of_opposite-1)){
			if(debug){p("Going S");}
			//go south even though to.y is to the North - to get over local obstacles (similar to hill climbing)
			r_point.y = from.y + random(y_dist/opposite_dir);
		}
		else if(direction_y=="S" && direction>(probability_of_opposite-1)){
			if(debug){p("Going S");}
			if(y_dist < jump_dist){
				r_point.y = to.y;// same as from.y + dist_y
			}
			else{
				r_point.y = from.y + random(y_dist);
			}
		}
		else if(direction_y=="S" && direction<=(probability_of_opposite-1)){
			if(debug){p("Going N");}
			//go North even though to.y is to the South - to get over local obstacles (similar to hill climbing)
			r_point.y = from.y - random(y_dist/opposite_dir);
		}
		r_point.x = from.x;
		//check bounds of y
		if(r_point.y > graphics_ymax){//S
			r_point.y = graphics_ymax;
		}
		else if(r_point.y < graphics_ymin){//N
			r_point.y = graphics_ymin;
		}
		if(debug){p("coords (from y): "+r_point.x+", "+r_point.y);}
	}
	return r_point;
}


protected var obstacles_placed:Boolean = false;
protected var start_pts_placed:Boolean = false;
protected var end_pts_placed:Boolean = false;
//protected var bitmap_obstacles:BitmapData = new BitmapData(rendering_area.width,rendering_area.height,true)
protected function place_obstacles():void{
	if(!obstacles_placed){
		//create new rectangle in the rendering area with random area
		var new_rect:Shape=new Shape();
		
		// display_object goes to container
		obstacle_container.addChild(new_rect);
		new_rect.graphics.beginFill(0xCCCCFF);
		var x:Number = random_x();
		var y:Number = random_y();
		var width:Number = random(max_obstacle_width);
		var height:Number = random(max_obstacle_height);
		
		//account for random cases that go beyond the rendering_area boundingbox
		if ((x + width) > graphics_xmax){
			width = graphics_xmax - x;
		}
		if ((y + height) > graphics_ymax){
			height = graphics_ymax - y;
		}
		new_rect.graphics.drawRect(0,0,width,height);
		//bitmap_obstacles.draw(new_rect);
		new_rect.x = x;
		new_rect.y = y;
		new_rect.graphics.endFill();
		p("Placing obstacles....id" +str(obstacles.length));
		status("Placing obstacles...");
		obstacles[obstacles.length] = new_rect;
		
		//recursion
		if(obstacles.length < obstacles_param){
			this.callLater(place_obstacles,[]);
		}
		else{
			obstacles_placed = true;
			p("Placing obstacles...DONE");
			status("Placing obstacles...DONE");
		}
	}
}


protected function place_start_pts():void{
	if(!start_pts_placed){
		var new_start_pt:Sprite=new Sprite();
		var number:String = str(start_pts.length);
			
		// display_object goes to container
		start_pt_container.addChild(new_start_pt);
		
		var x:Number = 0;
		var y:Number = 0;
		var radius:Number = 4;
		var test_point:Point= null;
		var occupied:Boolean = true;
		var number_field:TextField = new TextField();
		number_field.text = number;
		number_field.selectable = false;
		new_start_pt.addChild(number_field);
		
		
		new_start_pt.graphics.beginFill(0x00FF00);
		while(occupied){
			x = random_x();
			y = random_y();
			if (test_point != null){
				//p("Occupied moving from "+test_point.toString()+" to (" + x + "," +y+")");
			}
			
			//account for random cases that go beyond the rendering_area boundingbox
			if ((x + radius) > graphics_xmax){
				x = graphics_xmax - radius - 5;
			}
			if ((y + radius) > graphics_ymax){
				y = graphics_ymax - radius - 5;
			}
			if ((x - radius) < graphics_xmin){
				x = graphics_xmin + radius+5;
			}
			if ((y - radius) < graphics_ymin){
				y = graphics_ymin + radius+5;
			}
			test_point = new Point(x,y);
			occupied = false;
			
			//make sure start points are not on top of obstacles
			if (obstacle_container.getObjectsUnderPoint(test_point).length>0){
				occupied = true;
			}

		}
		new_start_pt.graphics.drawCircle(0,0,radius);
		new_start_pt.x = x;
		new_start_pt.y = y;
		new_start_pt.graphics.endFill();

		p("Placing start pts..." +str(start_pts.length));
		status("Placing start pts...");
		start_pts[start_pts.length] = new_start_pt;
		
		//recursion
		if(start_pts.length < start_pts_param){
			this.callLater(place_start_pts,[]);
		}
		else{
			start_pts_placed = true;
			p("Placing start pts...DONE");
			status("Placing start pts...DONE");
		}
	}
}

protected function place_end_pts():void{
	var number:String = str(end_pts.length);
	if(!end_pts_placed){
		//create new rectangle in the rendering area with random area
		var new_end_pt:Sprite=new Sprite();
		
		// display_object goes to container
		end_pt_container.addChild(new_end_pt);
		
		var x:Number = 0;
		var y:Number = 0;
		var radius:Number = 4;
		var test_point:Point= null;
		var occupied:Boolean = true;
		var number_field:TextField = new TextField();
		number_field.text = number;
		number_field.selectable = false;
		new_end_pt.addChild(number_field);
		
		
		new_end_pt.graphics.beginFill(0xFF0000);
		while(occupied){
			x = random_x();
			y = random_y();
			if (test_point != null){
				//p("Occupied moving from "+test_point.toString()+" to (" + x + "," +y+")");
			}
			
			//account for random cases that go beyond the rendering_area boundingbox
			if ((x + radius) > graphics_xmax){
				x = graphics_xmax - radius - 5;
			}
			if ((y + radius) > graphics_ymax){
				y = graphics_ymax - radius - 5;
			}
			if ((x - radius) < graphics_xmin){
				x = graphics_xmin + radius+5;
			}
			if ((y - radius) < graphics_ymin){
				y = graphics_ymin + radius+5;
			}
			test_point = new Point(x,y);
			occupied = false;
			
			//max sure start points are not on top of obstacles
			if (obstacle_container.getObjectsUnderPoint(test_point).length>0){
				occupied = true;
			}
		}
		new_end_pt.graphics.drawCircle(0,0,radius);
		
		new_end_pt.x = x;
		new_end_pt.y = y;
		new_end_pt.graphics.endFill();
	
		p("Placing end pts..." +str(end_pts.length));
		status("Placing end pts...");
		end_pts[end_pts.length] = new_end_pt;
		
		//recursion
		if(end_pts.length < end_pts_param){
			this.callLater(place_end_pts,[]);
		}
		else{
			end_pts_placed = true;
			p("Placing end pts...DONE");
			status("Placing end pts...DONE");
		}
	}
}



