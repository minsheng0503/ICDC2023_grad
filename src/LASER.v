`define CLK CLK
`define RST RST

module LASER (
input CLK,
input RST,
input [3:0] X,
input [3:0] Y,
output reg [3:0] C1X,
output reg [3:0] C1Y,
output reg [3:0] C2X,
output reg [3:0] C2Y,
output reg DONE);

reg [3:0] cs , ns;
reg [3:0] X_reg [39:0];
reg [3:0] Y_reg [39:0];
reg [5:0] counter;
reg [3:0] X_heart;
reg [3:0] Y_heart;
reg [3:0] a , b , c , d , e , f , g , h;
reg [5:0] count_in , count_both;
reg [5:0] max_dot , max_both;
reg [3:0] max_X_heart , max_Y_heart;
reg [3:0] max_X_heart2 , max_Y_heart2;
reg [3:0] max_X_heart_temp , max_Y_heart_temp;

localparam start = 0;
localparam store = 1;
localparam count_dot_temp = 2;
localparam count_dot = 3;
localparam move_heart = 4;
localparam start_move_heart = 5;
localparam count_dot2 = 6;
localparam move_heart2 = 7;
localparam start_move_heart2 = 8;
localparam count_dot3 = 9;
localparam move_heart3 = 10;
localparam change = 11;
localparam finish = 12;

integer i;

always @(posedge `CLK) begin
    if (RST) begin
        cs <= 4'd0;
    end
    else begin
        cs <= ns;
    end
end

always @(*) begin
    case (cs) //synopsys parallel_case
        start : ns = store;
        store : ns = counter == 6'd0 ? count_dot_temp : store;
        count_dot_temp : ns = count_dot;
        count_dot : ns = counter == 6'd40 ? move_heart : count_dot;
        move_heart : ns = {Y_heart , X_heart} == 8'h00 ? start_move_heart : count_dot;
        start_move_heart : ns = count_dot2;
        count_dot2 : ns = counter == 6'd40 ? move_heart2 : count_dot2;
        move_heart2 : ns = {Y_heart , X_heart} == 8'he2 ? start_move_heart2 : count_dot2;
        start_move_heart2 : ns = count_dot3;
        count_dot3 : ns = counter == 6'd40 ? move_heart3 : count_dot3;
        move_heart3 : ns = {Y_heart , X_heart} == {max_Y_heart_temp + 3'd4 , max_X_heart_temp - 2'd3} ? ((max_X_heart2 == max_X_heart_temp) && (max_Y_heart2 == max_Y_heart_temp) ? finish : change) : count_dot3;
        change : ns = start_move_heart2;
        finish : ns = start;
        default : ns = 4'd0;
    endcase
end

always @(posedge `CLK) begin
    if (RST) begin
        counter <= 6'd0;
    end
    else begin
        case (ns) //synopsys parallel_case
            store : counter <= counter == 6'd39 ? 6'd0 : counter + 1'b1;
            count_dot_temp : counter <= counter + 3'd4;
            count_dot : counter <= counter + 3'd4;
            move_heart : counter <= 6'd0;
            count_dot2 : counter <= counter + 2'd2;
            move_heart2 : counter <= 6'd0;
            count_dot3 : counter <= counter + 2'd2;
            move_heart3 : counter <= 6'd0;
        endcase
    end
end

always @(posedge `CLK) begin
    if (RST) begin
        for (i=0;i<40;i=i+1) begin
            X_reg[i] <= 4'd0;
            Y_reg[i] <= 4'd0;
        end
    end
    else if (ns == store) begin
        X_reg[0] <= X;
        for(i=0; i<39; i=i+1)begin
            X_reg[i+1] <= X_reg[i];
        end
        Y_reg[0] <= Y;
        for(i=0; i<39; i=i+1)begin
            Y_reg[i+1] <= Y_reg[i];
        end
    end
end

always @(posedge `CLK) begin
    if (RST) begin
        X_heart <= 4'd0;
        Y_heart <= 4'd0;
    end
    else begin
        case (ns) //synopsys parallel_case
            move_heart : begin
                X_heart <= X_heart + 1'b1;
                Y_heart <= X_heart == 4'd15 ? Y_heart + 1'b1 : Y_heart;
            end
            start_move_heart : begin
                X_heart <= 4'd2;
                Y_heart <= 4'd2;
            end
            move_heart2 : begin
                X_heart <= X_heart == 4'd13 ? 4'd2 : X_heart + 1'b1;
                Y_heart <= X_heart == 4'd13 ? Y_heart + 1'b1 : Y_heart;
            end
            start : begin
                X_heart <= 4'd0;
                Y_heart <= 4'd0;
            end
            start_move_heart2 : begin
                X_heart <= max_X_heart_temp - 2'd3;
                Y_heart <= max_Y_heart_temp - 2'd3;
            end
            move_heart3 : begin
                X_heart <= X_heart == max_X_heart_temp + 2'd3 ? max_X_heart_temp - 2'd3 : X_heart + 1'b1;
                Y_heart <= X_heart == max_X_heart_temp + 2'd3 ? Y_heart + 1'b1 : Y_heart;
            end
        endcase
    end
end

always @(*) begin
    case (ns) //synopsys parallel_case
        count_dot_temp : begin
            a = X_reg[0];
            b = Y_reg[0];
            c = X_reg[1];
            d = Y_reg[1];
            e = X_reg[2];
            f = Y_reg[2];
            g = X_reg[3];
            h = Y_reg[3];
        end
        count_dot : begin
            a = (X_reg[counter] >= X_heart) ? (X_reg[counter] - X_heart) : (X_heart - X_reg[counter]);
            b = (Y_reg[counter] >= Y_heart) ? (Y_reg[counter] - Y_heart) : (Y_heart - Y_reg[counter]);
            c = (X_reg[counter + 1'b1] >= X_heart) ? (X_reg[counter + 1'b1] - X_heart) : (X_heart - X_reg[counter + 1'b1]);
            d = (Y_reg[counter + 1'b1] >= Y_heart) ? (Y_reg[counter + 1'b1] - Y_heart) : (Y_heart - Y_reg[counter + 1'b1]);
            e = (X_reg[counter + 2'd2] >= X_heart) ? (X_reg[counter + 2'd2] - X_heart) : (X_heart - X_reg[counter + 2'd2]);
            f = (Y_reg[counter + 2'd2] >= Y_heart) ? (Y_reg[counter + 2'd2] - Y_heart) : (Y_heart - Y_reg[counter + 2'd2]);
            g = (X_reg[counter + 2'd3] >= X_heart) ? (X_reg[counter + 2'd3] - X_heart) : (X_heart - X_reg[counter + 2'd3]);
            h = (Y_reg[counter + 2'd3] >= Y_heart) ? (Y_reg[counter + 2'd3] - Y_heart) : (Y_heart - Y_reg[counter + 2'd3]);
        end
        count_dot2 : begin
            a = (X_reg[counter] >= X_heart) ? (X_reg[counter] - X_heart) : (X_heart - X_reg[counter]);
            b = (Y_reg[counter] >= Y_heart) ? (Y_reg[counter] - Y_heart) : (Y_heart - Y_reg[counter]);
            c = (X_reg[counter] >= max_X_heart) ? (X_reg[counter] - max_X_heart) : (max_X_heart - X_reg[counter]);
            d = (Y_reg[counter] >= max_Y_heart) ? (Y_reg[counter] - max_Y_heart) : (max_Y_heart - Y_reg[counter]);
            e = (X_reg[counter + 1'b1] >= X_heart) ? (X_reg[counter + 1'b1] - X_heart) : (X_heart - X_reg[counter + 1'b1]);
            f = (Y_reg[counter + 1'b1] >= Y_heart) ? (Y_reg[counter + 1'b1] - Y_heart) : (Y_heart - Y_reg[counter + 1'b1]);
            g = (X_reg[counter + 1'b1] >= max_X_heart) ? (X_reg[counter + 1'b1] - max_X_heart) : (max_X_heart - X_reg[counter + 1'b1]);
            h = (Y_reg[counter + 1'b1] >= max_Y_heart) ? (Y_reg[counter + 1'b1] - max_Y_heart) : (max_Y_heart - Y_reg[counter + 1'b1]);
        end
        count_dot3 : begin
            a = (X_reg[counter] >= X_heart) ? (X_reg[counter] - X_heart) : (X_heart - X_reg[counter]);
            b = (Y_reg[counter] >= Y_heart) ? (Y_reg[counter] - Y_heart) : (Y_heart - Y_reg[counter]);
            c = (X_reg[counter] >= max_X_heart) ? (X_reg[counter] - max_X_heart) : (max_X_heart - X_reg[counter]);
            d = (Y_reg[counter] >= max_Y_heart) ? (Y_reg[counter] - max_Y_heart) : (max_Y_heart - Y_reg[counter]);
            e = (X_reg[counter + 1'b1] >= X_heart) ? (X_reg[counter + 1'b1] - X_heart) : (X_heart - X_reg[counter + 1'b1]);
            f = (Y_reg[counter + 1'b1] >= Y_heart) ? (Y_reg[counter + 1'b1] - Y_heart) : (Y_heart - Y_reg[counter + 1'b1]);
            g = (X_reg[counter + 1'b1] >= max_X_heart) ? (X_reg[counter + 1'b1] - max_X_heart) : (max_X_heart - X_reg[counter + 1'b1]);
            h = (Y_reg[counter + 1'b1] >= max_Y_heart) ? (Y_reg[counter + 1'b1] - max_Y_heart) : (max_Y_heart - Y_reg[counter + 1'b1]);
        end
        default : begin
            a = 4'd0;
            b = 4'd0;
            c = 4'd0;
            d = 4'd0;
            e = 4'd0;
            f = 4'd0;
            g = 4'd0;
            h = 4'd0;
        end
    endcase
end

always @(posedge `CLK) begin
    if (RST) begin
        count_in <= 6'd0;
    end
    else begin
        case (ns) //synopsys parallel_case
            count_dot : count_in <= count_in + ((a+b <= 4) || (a == 3 && b == 2) || (a == 2 && b == 3)) + 
                                               ((c+d <= 4) || (c == 3 && d == 2) || (c == 2 && d == 3)) + 
                                               ((e+f <= 4) || (e == 3 && f == 2) || (e == 2 && f == 3)) + 
                                               ((g+h <= 4) || (g == 3 && h == 2) || (g == 2 && h == 3));
            move_heart : count_in <= 6'd0;
            count_dot2 : count_in <= count_in + (((a+b <= 4) || (a == 3 && b == 2) || (a == 2 && b == 3)) && ((c+d > 4) && (c != 3 && d != 2) && (c != 2 && d != 3))) + 
                                                (((e+f <= 4) || (e == 3 && f == 2) || (e == 2 && f == 3)) && ((g+h > 4) && (g != 3 && h != 2) && (g != 2 && h != 3)));
            move_heart2 : count_in <= 6'd0;
            count_dot3 : count_in <= count_in + (((a+b <= 4) || (a == 3 && b == 2) || (a == 2 && b == 3)) && (c+d > 4)) + 
                                                (((e+f <= 4) || (e == 3 && f == 2) || (e == 2 && f == 3)) && (g+h > 4));
            move_heart3 : count_in <= 6'd0;
        endcase
    end
end

always @(posedge `CLK) begin
    if (RST) begin
        count_both <= 6'd0;
    end
    else begin
        case (ns) //synopsys parallel_case
            count_dot2 : count_both <= count_both + (((a+b <= 4) || (a == 3 && b == 2) || (a == 2 && b == 3)) && ((c+d <= 4) || (c == 3 && d == 2) || (c == 2 && d == 3))) + 
                                                    (((e+f <= 4) || (e == 3 && f == 2) || (e == 2 && f == 3)) && ((g+h <= 4) || (g == 3 && h == 2) || (g == 2 && h == 3)));
            move_heart2 : count_both <= 6'd0;
            count_dot3 : count_both <= count_both + (((a+b <= 4) || (a == 3 && b == 2) || (a == 2 && b == 3)) && ((c+d <= 4) || (c == 3 && d == 2) || (c == 2 && d == 3))) + 
                                                    (((e+f <= 4) || (e == 3 && f == 2) || (e == 2 && f == 3)) && ((g+h <= 4) || (g == 3 && h == 2) || (g == 2 && h == 3)));
            move_heart3 : count_both <= 6'd0;
        endcase
    end
end

always @(posedge `CLK) begin
    if (RST) begin
        max_dot <= 6'd0;
    end
    else begin
        case (ns) //synopsys parallel_case
            move_heart : max_dot <= count_in > max_dot ? count_in : max_dot;
            start_move_heart : max_dot <= 6'd0;
            move_heart2 : max_dot <= ((count_in == max_dot) && (count_both >= max_both)) || (count_in >= max_dot) ? count_in : max_dot;
            start_move_heart2 : max_dot <= 6'd0;
            move_heart3 : max_dot <= ((count_in == max_dot) && (count_both >= max_both)) || (count_in >= max_dot) ? count_in : max_dot;
            finish : max_dot <= 6'd0;
        endcase
    end
end

always @(posedge `CLK) begin
    if (RST) begin
        max_X_heart <= 4'd0;
        max_Y_heart <= 4'd0;
    end
    else begin
        case (ns) //synopsys parallel_case
            move_heart : begin
                max_X_heart <= count_in > max_dot ? X_heart : max_X_heart;
                max_Y_heart <= count_in > max_dot ? Y_heart : max_Y_heart;
            end
            change : begin
                max_X_heart <= max_X_heart2;
                max_Y_heart <= max_Y_heart2;
            end
        endcase
    end
end

always @(posedge `CLK) begin
    if (RST) begin
        max_both <= 6'd0;
    end
    else begin
        case (ns) //synopsys parallel_case
            move_heart2 : max_both <= ((count_in == max_dot) && (count_both >= max_both)) || (count_in >= max_dot) ? count_both : max_both;
            move_heart3 : max_both <= ((count_in == max_dot) && (count_both >= max_both)) || (count_in >= max_dot) ? count_both : max_both;
            change : max_both <= 6'd0;
            finish : max_both <= 6'd0;
        endcase
    end
end

always @(posedge `CLK) begin
    if (RST) begin
        max_X_heart2 <= 4'd0;
        max_Y_heart2 <= 4'd0;
    end
    else if (ns == move_heart2 || ns == move_heart3) begin
        case (1'b1) //synopsys parallel_case
            count_in > max_dot : max_X_heart2 <= X_heart;
            count_in == max_dot : max_X_heart2 <= (count_both >= max_both) ? X_heart : max_X_heart2;
            count_in < max_dot : max_X_heart2 <= max_X_heart2;
        endcase

        case (1'b1) //synopsys parallel_case
            count_in > max_dot : max_Y_heart2 <= Y_heart;
            count_in == max_dot : max_Y_heart2 <= (count_both >= max_both) ? Y_heart : max_Y_heart2;
            count_in < max_dot : max_Y_heart2 <= max_Y_heart2;
        endcase
    end
end

always @(posedge `CLK) begin
    if (RST) begin
        max_X_heart_temp <= 4'd0;
        max_Y_heart_temp <= 4'd0;
    end
    else begin
        case (ns) //synopsys parallel_case
            start_move_heart : begin
                max_X_heart_temp <= max_X_heart;
                max_Y_heart_temp <= max_Y_heart;
            end
            change : begin
                max_X_heart_temp <= max_X_heart;
                max_Y_heart_temp <= max_Y_heart;
            end
            finish : begin
                max_X_heart_temp <= 4'd0;
                max_Y_heart_temp <= 4'd0;
            end
        endcase
    end
end

always @(posedge `CLK) begin
    if (RST) begin
        C1X <= 4'd0;
        C1Y <= 4'd0;
        C2X <= 4'd0;
        C2Y <= 4'd0;
        DONE <= 1'b0;
    end
    else if (ns == finish) begin
        C1X <= max_X_heart;
        C1Y <= max_Y_heart;
        C2X <= max_X_heart2;
        C2Y <= max_Y_heart2;
        DONE <= 1'b1;
    end
    else begin
        DONE <= 1'b0;
    end
end

endmodule
