with Ada.Wide_Text_IO; use Ada.Wide_Text_IO;
with Ada.Strings.Wide_Fixed; use Ada.Strings.Wide_Fixed;
with Ada.Strings; use Ada.Strings;

procedure Lab1Ada is
   
   protected type Stop_Flag is
      procedure Set;
      procedure Reset;
      function Get return Boolean;
   private
      Value : Boolean := False;
   end Stop_Flag;

   protected body Stop_Flag is
      procedure Set is begin Value := True; end Set;
      procedure Reset is begin Value := False; end Reset;
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

   task type Work_Thread is
      entry Start (Id : Integer; Step : Long_Long_Integer; Time : Integer);
   end Work_Thread;

   task type Master_Break_Thread is
      entry Start (N : Integer);
   end Master_Break_Thread;

   Times : array (1 .. 100) of Integer; 
   Flags : array (1 .. 100) of Stop_Flag;

   task body Work_Thread is
      My_Id : Integer;
      My_Step : Long_Long_Integer;
      My_Time : Integer;
      Sum : Long_Long_Integer := 0;
      Elements_Count : Long_Long_Integer := 0;
   begin
      accept Start (Id : Integer; Step : Long_Long_Integer; Time : Integer) do
         My_Id := Id;
         My_Step := Step;
         My_Time := Time;
      end Start;

      loop
         Sum := Sum + My_Step;
         Elements_Count := Elements_Count + 1;
         exit when Flags(My_Id).Get;
      end loop;

      Output_Lock.Seize;
      Put_Line (Trim(Integer'Wide_Image(My_Id), Both) & " - " & 
                Trim(Long_Long_Integer'Wide_Image(Sum), Both) & ", " & 
                Trim(Long_Long_Integer'Wide_Image(My_Step), Both) & " - " & 
                Trim(Long_Long_Integer'Wide_Image(Elements_Count), Both) & " разів за " &
                Trim(Integer'Wide_Image(My_Time), Both) & " сек.");
      Output_Lock.Release;
   end Work_Thread;

   task body Master_Break_Thread is
      My_N : Integer;

      type Event_Record is record
         Time  : Integer;
         Index : Positive;
      end record;
      type Event_Array is array (Positive range <>) of Event_Record;

      Elapsed : Integer;
      Sleep_Time : Integer;
      Temp : Event_Record;
   begin
      accept Start (N : Integer) do
         My_N := N;
      end Start;

      declare
         Events : Event_Array (1 .. My_N);
      begin
         for I in 1 .. My_N loop
            Events(I) := (Time => Times(I), Index => I);
         end loop;

         for I in 1 .. My_N - 1 loop
            for J in 1 .. My_N - I loop
               if Events(J).Time > Events(J + 1).Time then
                  Temp := Events(J);
                  Events(J) := Events(J + 1);
                  Events(J + 1) := Temp;
               end if;
            end loop;
         end loop;

         Elapsed := 0;
         for I in 1 .. My_N loop
            Sleep_Time := Events(I).Time - Elapsed;
            if Sleep_Time > 0 then
               delay Duration(Sleep_Time);
               Elapsed := Elapsed + Sleep_Time;
            end if;
            Flags(Events(I).Index).Set;
         end loop;
      end;
   end Master_Break_Thread;

   Step_Input : Long_Long_Integer;
   Input_Line : Wide_String (1 .. 256);
   Last_Idx : Natural;
   Num_Threads : Natural := 0;
   Max_Time : Integer;
   
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

      Max_Time := 0;
      for K in 1 .. Num_Threads loop
         if Times(K) > Max_Time then
            Max_Time := Times(K);
         end if;
      end loop;

      declare
         Works  : array (1 .. Num_Threads) of Work_Thread;
         Master : Master_Break_Thread;
      begin
         for K in 1 .. Num_Threads loop
            Flags(K).Reset;
            Works(K).Start(K, Step_Input, Times(K));
         end loop;
         
         Master.Start(Num_Threads);
         
         delay Duration(Max_Time + 1);
      end;
      
      Put_Line ("Усі потоки завершили роботу. Починаємо новий цикл.");
      Put_Line ("");
   end loop Main_Loop;
end Lab1Ada;