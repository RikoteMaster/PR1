module fifo_ideal
  (	input 	clk,  reset,
   input [7:0] dato_entrada,
   input read,write,
   output logic [7:0] dato_salida,
   output logic [4:0] use_dw,
	output logic lleno,vacio);
  
  
logic [7:0] cola [$:31] ;

  
always_ff @(negedge reset, posedge clk)
if (!reset)
  cola.delete(); 
else
    case ({read,write})
      2'b01: cola.push_front(dato_entrada);
      2'b10: dato_salida=cola.pop_back(); 
      2'b11: begin 

        if (cola.size==0)
        	begin
              cola.push_front(dato_entrada);              
              dato_salida=cola.pop_back(); 
            end
        else
        	begin
              dato_salida=cola.pop_back(); 
              cola.push_front(dato_entrada);
            end
      end
    endcase
  

 assign use_dw=cola.size();
 assign lleno=cola.size()==32;
 assign vacio=cola.size()==0;      

 
/*property  llenado ;
    (@(posedge clk) not (write==1'b1 && lleno==1'b1 &&read==1'b0));
endproperty
sobrellenado:assert property (llenado)  else $error("estas escribiendo sobre una fifo llena");

property  vaciado ;
  (@(posedge clk) not (read==1'b1 && vacio==1'b1&& write==1'b0)) ;
endproperty
sobrevaciado:assert property  (vaciado) else $error("estas leyendo de una fifo vacia");

nodeberia1:assert property (@(posedge clk)  $fell(vacio) |=> not (use_dw=='0));*/
  

endmodule 