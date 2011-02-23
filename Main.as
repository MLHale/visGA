
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
protected var start_pts_param:int = 20;
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
protected var debug:Boolean = true;
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
	this.addEventListener(Event.ENTER_FRAME,main_loop);
}

/* helper functions */
protected function p(text:String):void{
	console_pane.appendText(this+">"+text+"\n");
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
		return Math.floor(Math.random() * (max - min[0])) + min[0];
	}
	else{
		return Math.floor(Math.random()*max);
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
				this.callLater(generate_population,[]);
			}
		}
	}
}
protected var started:Boolean = false;
protected var isPaused:Boolean = false;
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
protected function generate_population():void{
	//p("Current member.length"+str(member.length));
	if(!isPaused){
		if(!processing_individual && population.length < max_pop){
			processing_population = true;
			
			if(member.length == start_pts.length){
				//only add fully completed arrays
				trace("member completed...calculating fitness");
				member.fitness = fitness_function(member);
				fit_p(member.id + " "+str(member.fitness));

				population.addItem(member);
				
				//clear current lines
				trace("Number of children to remove: "+line_container.numChildren);
				//line_container.removeAllChildren();
				this.removeElement(line_container);
				line_container = new UIComponent();
				this.addElement(line_container);
				System.gc();
				
			}
			//new member
			member = new Individual();
			member.id = str(population.length);

			p("Creating individual...");
			status("Creating individual...");
			trace("Calling creat_individual (from pop) ");
			this.callLater(create_individual,[]);	
		}
		else if(processing_individual && population.length < max_pop){
			//currently processing individual just wait
			this.callLater(generate_population,[])
		}
		else{
			//population is > max_pop = > done processing for now
			//processing_population = false;
			//for debug only!!!! - just to get the first generation and stop
			processing_population = true;
		}
	}
}
protected function create_individual(curr_line:Number=0):void{
	processing_individual = true;
	var new_line:Line=new Line();
	
	//Points to connect
	var from:Point = new Point(start_pts[curr_line].x,start_pts[curr_line].y);
	var to:Point = new Point(end_pts[curr_line].x,end_pts[curr_line].y);
	
	// display_object goes to container
	line_container.addChild(new_line);
	
	//commands 1 = moveTo(), 2 = lineTo()
	var line_commands:Vector.<int> = new Vector.<int>(); 
	
	var line_coord:Vector.<Number> = new Vector.<Number>();
	
	//generate random x, y path between from and to
	var curr_pt:Point = random_point(from,to);
	line_commands.push(1);
	line_coord.push(from.x,from.y);
	while(curr_pt.x != to.x && curr_pt.y != to.y){
		line_commands.push(2);
		line_coord.push(curr_pt.x,curr_pt.y);
		curr_pt = random_point(curr_pt,to);
	}

	p("Created line"+line_coord.toString());
	
	//set line style (thickness, color)
	new_line.graphics.lineStyle(1,0x000000)
	new_line.graphics.drawPath(line_commands,line_coord);
	
	//increment the Individual's total distance
	var distance_num:Number = 0;
	distance_num = distance(from.x,from.y,to.x,to.y);
	member.addItem(new_line);
	member.increment_distance(distance_num);
	
	
	//recursion
	curr_line++;
	if(curr_line < start_pts.length){
		this.callLater(create_individual,[curr_line]);
		status("Calculating lines...");
	}
	else{
		processing_individual = false;
		status("Calculating lines...DONE");
		trace("Calling generate_pop() curr_line="+curr_line);
		this.callLater(generate_population,[])
	}
}
protected function distance(x1:Number,y1:Number,x2:Number,y2:Number):Number{
	return Math.sqrt((Math.pow((x1 - x2),2) + Math.pow((y1 - y2),2))); 
}
protected function random_point(from:Point,to:Point):Point{
	var direction_x:String = "";
	var direction_y:String = "";
	var r_point:Point = new Point();
	
	
	if (from.x > to.x){
		//go east
		direction_x="E";
	}
	else{
		direction_x="W";
	}
	if(from.y > to.y){
		//go North
		direction_y="N";
	}
	else{
		direction_y="S";
	}
	var axis:Number = random(2);
	var direction:Number = random(4); //75% chance to go towards to.x 25% to go opposite way
	if(direction==1){
		//move along x
		var x_dist:Number = distance(from.x,0,to.x,0);
		if(direction_x=="E" && direction>=2){
			if(x_dist < 100){
				r_point.x = to.x;// same as from.x - dist_x
			}
			else{
				r_point.x = from.x - random(x_dist);
			}
		}
		else if(direction_x=="E" && direction==1){
			//go west even though to.x is to the east - to get over local obstacles (similar to hill climbing)
			r_point.x = from.x + random(x_dist/2);
		}
		else if(direction_x=="W" && direction>=2){
			if(x_dist < 100){
				r_point.x = to.x;// same as from.x + dist_x
			}
			else{
				r_point.x = from.x + random(x_dist);
			}
		}
		else if(direction_x=="W" && direction==1){
			//go east even though to.x is to the west - to get over local obstacles (similar to hill climbing)
			r_point.x = from.x - random(x_dist/2);
		}
	}
	else if(direction==2){
		//move along y
		var y_dist:Number = distance(0,from.y,0,to.y);
		if(direction_x=="N" && direction>=2){
			if(y_dist < 100){
				r_point.y = to.y;// same as from.y - dist_y
			}
			else{
				r_point.y = from.y - random(y_dist);
			}
		}
		else if(direction_x=="N" && direction==1){
			//go south even though to.y is to the North - to get over local obstacles (similar to hill climbing)
			r_point.y = from.y + random(y_dist/2);
		}
		else if(direction_x=="S" && direction>=2){
			if(y_dist < 100){
				r_point.y = to.y;// same as from.y + dist_y
			}
			else{
				r_point.y = from.y + random(y_dist);
			}
		}
		else if(direction_x=="S" && direction==1){
			//go North even though to.y is to the South - to get over local obstacles (similar to hill climbing)
			r_point.y = from.y - random(y_dist/2);
		}
	}
	
	return r_point;
}
protected function fitness_function(member:Individual):Number{
	var fitness:Number = 0;
	fitness = member.distance;
	trace("Fitness = "+member.distance);
	return fitness;
}

protected var obstacles_placed:Boolean = false;
protected var start_pts_placed:Boolean = false;
protected var end_pts_placed:Boolean = false;
protected var bitmap_obstacles:BitmapData = new BitmapData(rendering_area.width,rendering_area.height,true)
protected function place_obstacles():void{
	if(!obstacles_placed){
		//create new rectangle in the rendering area with random area
		var new_rect:Sprite=new Sprite();
		
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
		//new_rect.graphics.drawRect(0,0,width,height);
		bitmap_obstacles.draw(new_rect);
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



