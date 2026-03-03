with Ada.Wide_Text_IO; use Ada.Wide_Text_IO;
with Ada.Strings.Wide_Fixed; use Ada.Strings.Wide_Fixed;
with Ada.Strings; use Ada.Strings;

procedure Lab1Ada is
   
   protected type Stop_Flag is
      procedure Set;
      function Get return Boolean;
   private
      Value : Boolean := False;
   end Stop_Flag;

   protected body Stop_Flag is
      procedure Set is begin Value := True; end Set;
      function Get return Boolean is begin return Value; end Get;
   end Stop_Flag;

   protected Output_Lock is
      entry Seize;
      procedure Release;
   private
      Locked : Boolean := False;
   end Output_Lock;

   protected body Output_Lock is
      entry Seize when not Locked is
      begin
         Locked := True;
      end Seize;

      procedure Release is
      begin
         Locked := False;
      end Release;
   end Output_Lock;

   type Stop_Flag_Access is access Stop_Flag;

   task type Main_Thread is
      entry Start (Id : Integer; Step : Long_Long_Integer; Time : Integer; Flag : Stop_Flag_Access);
   end Main_Thread;

   task type Break_Thread is
      entry Start (Seconds : Integer; Flag : Stop_Flag_Access);
   end Break_Thread;

   task body Main_Thread is
      My_Id : Integer;
      My_Step : Long_Long_Integer;
      My_Time : Integer;
      My_Flag : Stop_Flag_Access;
      Sum : Long_Long_Integer := 0;
      Elements_Count : Long_Long_Integer := 0;
   begin
      accept Start (Id : Integer; Step : Long_Long_Integer; Time : Integer; Flag : Stop_Flag_Access) do
         My_Id := Id;
         My_Step := Step;
         My_Time := Time;
         My_Flag := Flag;
      end Start;

      loop
         Sum := Sum + My_Step;
         Elements_Count := Elements_Count + 1;
         exit when My_Flag.Get;
      end loop;

      Output_Lock.Seize;
      Put_Line (Trim(Integer'Wide_Image(My_Id), Both) & " - " & 
                Trim(Long_Long_Integer'Wide_Image(Sum), Both) & ", " & 
                Trim(Long_Long_Integer'Wide_Image(My_Step), Both) & " - " & 
                Trim(Long_Long_Integer'Wide_Image(Elements_Count), Both) & " разів за " &
                Trim(Integer'Wide_Image(My_Time), Both) & " сек.");
      Output_Lock.Release;
   end Main_Thread;

   task body Break_Thread is
      My_Seconds : Integer;
      My_Flag : Stop_Flag_Access;
   begin
      accept Start (Seconds : Integer; Flag : Stop_Flag_Access) do
         My_Seconds := Seconds;
         My_Flag := Flag;
      end Start;
      
      delay Duration(My_Seconds);
      My_Flag.Set;
   end Break_Thread;

   Step_Input : Long_Long_Integer;
   Input_Line : Wide_String (1 .. 256);
   Last_Idx : Natural;
   Num_Threads : Natural := 0;
   Times : array (1 .. 100) of Integer; 
   
   Valid_Step : Boolean;
   Valid_Times : Boolean;
   I, J : Positive;
   
begin
   Main_Loop : loop
      Valid_Step := False;
      while not Valid_Step loop
         Put_Line ("Введіть крок роботи потоків (0 для виходу)");
         begin
            Get_Line (Input_Line, Last_Idx);
            Step_Input := Long_Long_Integer'Wide_Value(Input_Line(1 .. Last_Idx));
            if Step_Input = 0 then
               Put_Line ("Програма завершує роботу.");
               exit Main_Loop;
            elsif Step_Input > 0 then
               Valid_Step := True;
            else
               Put_Line ("Помилка вводу. Будь ласка, введіть ціле додатне число або 0 для виходу.");
            end if;
         exception
            when others =>
               Put_Line ("Помилка вводу. Будь ласка, введіть ціле додатне число або 0 для виходу.");
         end;
      end loop;

      Valid_Times := False;
      while not Valid_Times loop
         Put_Line ("Введіть час роботи потоків у секундах через пробіл");
         Get_Line (Input_Line, Last_Idx);
         
         Num_Threads := 0;
         I := 1;
         Valid_Times := True;
         
         if Last_Idx = 0 then
            Valid_Times := False;
         else
            while I <= Last_Idx loop
               while I <= Last_Idx and then Input_Line(I) = ' ' loop
                  I := I + 1;
               end loop;
               if I <= Last_Idx then
                  J := I;
                  while J <= Last_Idx and then Input_Line(J) /= ' ' loop
                     J := J + 1;
                  end loop;
                  
                  begin
                     Num_Threads := Num_Threads + 1;
                     Times(Num_Threads) := Integer'Wide_Value(Input_Line(I .. J - 1));
                     if Times(Num_Threads) <= 0 then
                        Valid_Times := False;
                        exit;
                     end if;
                  exception
                     when others =>
                        Valid_Times := False;
                        exit;
                  end;
                  I := J;
               end if;
            end loop;
            
            if Num_Threads = 0 then
               Valid_Times := False;
            end if;
         end if;
         
         if not Valid_Times then
            Put_Line ("Помилка вводу. Переконайтеся, що ви ввели лише цілі додатні числа через пробіл.");
         end if;
      end loop;

      declare
         Flags  : array (1 .. Num_Threads) of Stop_Flag_Access;
         Mains  : array (1 .. Num_Threads) of Main_Thread;
         Breaks : array (1 .. Num_Threads) of Break_Thread;
      begin
         for K in 1 .. Num_Threads loop
            Flags(K) := new Stop_Flag;
            Mains(K).Start(K, Step_Input, Times(K), Flags(K));
            Breaks(K).Start(Times(K), Flags(K));
         end loop;
      end;
      
      Put_Line ("Усі потоки завершили роботу. Починаємо новий цикл.");
      Put_Line ("");
   end loop Main_Loop;
end Lab1Ada;