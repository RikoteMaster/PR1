class id;
  rand bit [1:0]  valor;
  constraint llenar {valor dist {2'b10 := 5, 2'b01 := 2, 2'b11:=3, 2'b00:=4};}
  constraint vaciar {valor dist {2'b10:=2, 2'b01:=5, 2'b11:=3, 2'b00:=4};}
endclass;


module fifo_tb  #(
        parameter WIDTH = 16
) ();
			  logic                 clk_i;
			  logic               clear_n;
			  logic               rst_n_i;
			  logic                  we_i;
			  logic                  re_i;
			  logic         [7:0] data_in;
			  logic          [7:0] data_o;
        logic                 empty;
        logic                  full;
		  	logic           [4:0] usedw;
        logic         [7:0] data_o2;
        logic          [4:0] usedw2;
        logic          full2,empty2;




 subtarea1 subtarea1_inst
(
        .DATA_IN(data_in) ,        // input [0:7] DATA_IN_sig
        .READ(re_i) ,        // input  READ_sig
        .WRITE(we_i) ,        // input  WRITE_sig
        .CLEAR_N(clear_n) ,        // input  CLEAR_N_sig
        .RESET_N(rst_n_i) ,        // input  RESET_N_sig
        .CLOCK(clk_i) ,        // input  CLOCK_sig
        .DATA_OUT(data_o) ,        // output [0:7] DATA_OUT_sig
        .F_FULL_N(full) ,        // output  F_FULL_N_sig
        .F_EMPTY_N(empty) ,        // output  F_EMPTY_N_sig
        .USE_DW(usedw)         // output [4:0] USE_DW_sig
);

fifo_ideal fifo_ideal(clk_i, rst_n_i, data_in, re_i, we_i, data_o2, usedw2, full2, empty2);
initial forever #10 clk_i = ~clk_i;






task write(input [7:0] input_data);
    @(negedge clk_i)
      we_i = 1;
      data_in = input_data;
    @(negedge clk_i)
      we_i = 0;
      CHECK_GM();
endtask

task read();
    @(negedge clk_i)
      re_i = 1;
    @(negedge clk_i)
      re_i = 0;
      CHECK_GM();
endtask

task reset();
    @(negedge clk_i)
      rst_n_i = 0;
    @(negedge clk_i)
      rst_n_i = 1;
      CHECK_GM();

  endtask
task clear();
    @(negedge clk_i)
      clear_n = 0;
    @(negedge clk_i)
      clear_n = 1;
      CHECK_GM();
endtask

task lleno_memoria();
  for(int i=0; i<=31;i++)
	  write($random());
    CHECK_GM();
endtask

task vacio_memoria();
  for(int i=0; i<=31;i++)
	  read();
    CHECK_GM();

endtask

task escritura_lectura ();
  @(negedge clk_i) //escritura y lectura simultanea
    we_i=1;
	  data_in= $random();
	  re_i=1;

  @(negedge clk_i)
    we_i=0;
	  re_i=0;
    CHECK_GM();
endtask
id item;

task automatic CHECK_GM;
		if ($time > 20)
			begin
			if (data_o != data_o2)
				begin
					$display("Error de lectura de datos en ", $time);
					$display("Datos leidos del disenyo: ", data_o);
					$display("Datos leidos del golden model: ", data_o2);
				end
				
			else if (usedw != usedw2)
				begin
					$display("Error de numero de datos almacenados en ", $time);
					$display("Datos almacenados en el disenyo: ", usedw);
					$display("Datos almacenados en el golden model: ", usedw2);
				end
				
			else if (full != !full2)
				begin
					$display("Error de senyal de llenado en ", $time);
				end
				
			else if (empty != !empty2)
				begin
					$display("Error de senyal de vaciado en ", $time);
				end
			end
	endtask


task llenado_vaciado_aleatorio;
     begin

       while (full)
        begin
          @(negedge clk_i);
         item.vaciar.constraint_mode(0);
           item.randomize();

          if(item.valor == 2'b10 || item.valor == 2'b11)
            data_in = $random();
          
          {we_i,re_i}=item.valor;
          CHECK_GM();
        end
       while (empty)
        begin
          @(negedge clk_i);
          item.vaciar.constraint_mode(1);
          item.llenar.constraint_mode(0);
           item.randomize();

          if(item.valor == 2'b10 || item.valor == 2'b11)
            data_in = $random();

          {we_i,re_i}=item.valor;
          CHECK_GM();
        end




end
endtask


initial begin
  item=new();

  clk_i = 0;
  clear_n = 1;
  rst_n_i = 1;
  we_i = 0;
  re_i = 0;
  reset();

  //En esta verificaci�n lo que vamos a realizar ser�, pasar por todos los estados simult�neamente y comprobar en cada uno de ellos, que se puede
  // realizar de manera correcta escritura y lectura simult�nea.

  
  lleno_memoria();
  write($random());
  vacio_memoria();
  read();
  escritura_lectura();


  write($random());
  write($random());
  write($random());

  escritura_lectura();

	read();
	read();
	read();
  lleno_memoria(); //llenado de memoria
  escritura_lectura();


  write($random());
  reset();
  llenado_vaciado_aleatorio();

  $finish;

 

end



initial begin
  $dumpfile ("fifo.vcd");
  $dumpvars;
end


endmodule