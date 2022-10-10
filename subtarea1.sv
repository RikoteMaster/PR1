module subtarea1 (
input [0:7]DATA_IN,
input READ,WRITE,CLEAR_N,RESET_N,CLOCK,
output [0:7] DATA_OUT,
output  F_FULL_N, F_EMPTY_N, 
output [4:0] USE_DW);



/*****************************************CONTROLPATH*****************************************/


/*En este momento vamos a establecer todas las señales auxiliares necesarias para nuestro diseño, de entre ellas se encuentran
las necesarias para el cambio de estado : estado y estado sig, ambas tendrán un tamaño de dos bits ya que nuestra ASM contará con 3 estados
Posteriormente hemos definido señales auxiliares tales como:
1. enablew, enabler, enabledw: todas estas son señales creadas por nosotros y usadas como enable de los contadores de escritura, lectura y 
el contador de uso de la memoria de la ram. Todas activas a nivel alto. 
2. up_down: Esta señal es utilizada para el control de la cuenta de llenado de ram. Si se está escribiendo en la ram, up_down = 1.
Mientras que si se está leyendo de la misma up_down = 0.
3. sel y manener: Estas señales las hemos generado para seleccionar el DATA_OUT, cuando queramos seleccionar el valor que entra en el diseño
sel = 1, cuando queramos seleccionar el valor que sale de la ram sel = 0. El registro mantener tiene un uso más concreto. Ha sido diseñado 
para que cuando realicemos una lectura y escritura simúltanea estando en el estado de vacío mantenga el valor que ha sido escrito hasta que 
se realice una lectura.
El resto de señales definidas debajo se han utilizado simplemente para la interconexión de señales del datapath.
*/
	reg		[1:0]estado, estado_sig;
	
	reg enablew, enabler, enabledw,  up_down, sel, mantener; 
	parameter vacio = 0, otros = 1, lleno = 2;
	wire TC1, TC2;
	wire [7:0] data_ram_aux;


	
always @(posedge CLOCK or negedge RESET_N) //Bloque secuencial en el que asginamos el siguiente valor del estado.
begin
	if(!RESET_N)
		estado <= vacio;
	else if (!CLEAR_N)
		estado <= vacio; 
	else estado <= estado_sig;
end



//bloque combinacional  actualizacion estado siguiente
always @(*)

case (estado)
	vacio: if(WRITE && !READ) estado_sig=otros;
			 else estado_sig = vacio;
		
		
	otros: if(READ && !WRITE && TC2) estado_sig= vacio;
			 else if(WRITE && !READ && TC1) estado_sig = lleno;
			 else estado_sig=otros;
			 
	lleno: if (!WRITE && READ) estado_sig=otros;
			 else estado_sig = lleno;
			 
	default: estado_sig = vacio;

endcase
	wire [1:0] AUX; /*Creación de un wire AUX cuyo valor será la concatencación de las entradas WRITE READ para facilitar la asignacion de salidas*/
	assign AUX = {WRITE,READ};
	
	always @ (AUX,WRITE,READ,estado,TC1,TC2)
	
	begin
			mantener = 0; sel = 0; //Definimos estado por defecto de estas señales ya que las vamos a modificar en pocas ocasiones
			case (estado) 
				vacio: 
				
					begin
					
					if ( WRITE == 1'b1 )
					
						if(READ == 1'b1)
						begin
							 mantener = 1; sel = 1; up_down=1;  enabler= 0; enablew = 0; enabledw = 0;
							
						end
						else 
						begin
							 up_down = 1;  enabler = 0; enablew = 1; enabledw = 1;
						end
					else
						begin
							 up_down = 1 ;  enabler = 0; enablew = 0; enabledw = 0;
						end
					end	
				otros:
					begin
						
						case(AUX)
							2'b00:
							begin
								up_down = 1; enabler = 0; enablew = 0; enabledw = 0;				
							end
							2'b01:
							begin
								mantener = 1; up_down = 0; enabler = 1; enablew = 0; enabledw = 1;
							end
							2'b10:
							begin
								up_down = 1; enabler = 0; enablew = 1; enabledw = 1;
							end
							2'b11:
							begin
								mantener = 1; up_down = 1; enabler = 1; enablew = 1; enabledw = 0;			
							end
						endcase
					end
					
				lleno:
					begin
						
											
						case(AUX)
						2'b00:
						begin
							up_down = 1; enabler = 0; enablew = 0; enabledw = 0;				
						end
						2'b01:
						begin
							mantener = 1; sel = 0; up_down = 0; enabler = 1; enablew = 0; enabledw = 1;
						end
						2'b10:
						begin
							up_down = 1; enabler = 0; enablew = 0; enabledw = 0;
						end
						2'b11:
						begin
							mantener = 1; up_down = 1; enabler = 1; enablew = 1; enabledw = 0;
						end
				default: 
						begin
							up_down = 1; enabler = 0; enablew = 0; enabledw = 0;
						end
						
					endcase
					
				end
		default: 
						begin

							up_down = 1; enabler = 0; enablew = 0; enabledw = 0;
						end
					
					
		endcase
	end

/*****************************************DATAPATH*****************************************/

assign F_EMPTY_N = ( estado == vacio ) ? 1'b0 : 1'b1;
assign F_FULL_N  = ( estado == lleno ) ? 1'b0 : 1'b1;

/***************************REGISTRO****************************/


//NECESITAOMS REGISTRAR LAS ENTRADAS DEL SELECTOR DE DATOS, LA SALIDA DE LA RAM YA ESTABA REGISTRADA LO QUE ES NECESARIO ES REGISTRAR datos de ram

reg [7:0] data_aux;
reg selreg, mantener_reg; 
always @(posedge CLOCK) begin
	if(mantener)
		selreg <= sel;
		

end


always @(posedge CLOCK) begin
		if(sel)
			data_aux <= DATA_IN; 

end

assign DATA_OUT = selreg ? data_aux : data_ram_aux;


/***************************CONTADORDW-UPDOWN****************************/
binary_counter binary_counter_inst
(
	.clk(CLOCK) ,	// input  clk_sig
	.clear_n(CLEAR_N) ,	// input  clear_n_sig
	.enable(enabledw) ,	// input  enable_sig
	.up_down(up_down) ,	// input  count_up_sig
	.reset(RESET_N) ,	// input  reset_sig
	.count(USE_DW) ,	// output [WIDTH:0] count_sig
	.TC1(TC1) ,	// output  TC1_sig
	.TC2(TC2) 	// output  TC2_sig
);

defparam binary_counter_inst.MODULO = 32;
//defparam binary_counter_inst.WIDTH = ;

/***************************CONTADORWRITE****************************/
wire [4:0] countw;
contador_normal contadorw(CLOCK, enablew, RESET_N, CLEAR_N, countw);
defparam contadorw.final_count = 32;

/***************************CONTADORWREAD****************************/
wire [4:0] countr;
contador_normal contadorr(CLOCK, enabler, RESET_N, CLEAR_N, countr);
defparam contadorr.final_count = 32;
/***************************RAMDP****************************/
ram_dp ram_dp
(
	.data_in(DATA_IN),
	.wren((WRITE && READ && !F_FULL_N && F_EMPTY_N) || (WRITE && F_FULL_N)),
	.clock(CLOCK),
	.rden(READ && F_EMPTY_N),
	.wraddress(countw),
	.rdaddress(countr),
	.data_out(data_ram_aux)
	
);

/*ASSERT PARA SI SUCEDEN EXCEPCIONES LAS AVISE POR PANTALLA*/


/*property  llenado ;
    (@(posedge CLOCK) not (WRITE==1'b1 && F_FULL_N==1'b0 && READ==1'b0));
endproperty
sobrellenado: assert property (llenado)  else $error("estas escribiendo sobre una fifo llena");

property  vaciado ;
  (@(posedge CLOCK) not (READ==1'b1 && F_EMPTY_N==1'b0 && WRITE==1'b0)) ;
endproperty
sobrevaciado:assert property  (vaciado) else $error("estas leyendo de una fifo vacia");

nodeberia1: assert property (@(posedge CLOCK)  $rose(F_EMPTY_N) |=> not (USE_DW=='0)); 
nodeberia2: assert property (@(posedge CLOCK)  F_FULL_N == 1'b0  |->  (USE_DW=='0));*/
  
endmodule 