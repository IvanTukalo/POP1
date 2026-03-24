with Ada.Wide_Text_IO; use Ada.Wide_Text_IO;
with Ada.Strings.Wide_Fixed; use Ada.Strings.Wide_Fixed;
with Ada.Strings; use Ada.Strings;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Numerics.Discrete_Random;

procedure Lab2Ada is
   Dim : constant Integer := 2_000_000_000;

   type Int_Array is array (Integer range <>) of Integer;
   type Int_Array_Access is access Int_Array;
   Arr : Int_Array_Access;

   subtype Val_Range is Integer range 1 .. 100;
   package Rand_Val is new Ada.Numerics.Discrete_Random (Val_Range);
   Gen_Val : Rand_Val.Generator;

   subtype Idx_Range is Integer range 0 .. Dim - 1;
   package Rand_Idx is new Ada.Numerics.Discrete_Random (Idx_Range);
   Gen_Idx : Rand_Idx.Generator;

   package Wide_Float_IO is new Ada.Wide_Text_IO.Float_IO (Float);

   protected Global_Result is
      procedure Update (L_Min, L_Idx : Integer);
      procedure Reset;
      function Get_Min return Integer;
      function Get_Idx return Integer;
   private
      Min_V : Integer := Integer'Last;
      Idx_V : Integer := -1;
   end Global_Result;

   protected body Global_Result is
      procedure Update (L_Min, L_Idx : Integer) is
      begin
         if L_Min < Min_V then
            Min_V := L_Min;
            Idx_V := L_Idx;
         end if;
      end Update;

      procedure Reset is
      begin
         Min_V := Integer'Last;
         Idx_V := -1;
      end Reset;

      function Get_Min return Integer is
      begin
         return Min_V;
      end Get_Min;

      function Get_Idx return Integer is
      begin
         return Idx_V;
      end Get_Idx;
   end Global_Result;

   procedure Find_Min
     (Start_I, End_I : Integer;
      R_Min, R_Idx   : out Integer)
   is
      L_Min : Integer := Integer'Last;
      L_Idx : Integer := -1;
   begin
      for I in Start_I .. End_I - 1 loop
         if Arr (I) < L_Min then
            L_Min := Arr (I);
            L_Idx := I;
         end if;
      end loop;
      R_Min := L_Min;
      R_Idx := L_Idx;
   end Find_Min;

   task type Worker is
      entry Start (Start_I, End_I : Integer);
   end Worker;

   task body Worker is
      S_I, E_I, L_Min, L_Idx : Integer;
   begin
      accept Start (Start_I, End_I : Integer) do
         S_I := Start_I;
         E_I := End_I;
      end Start;

      Find_Min (S_I, E_I, L_Min, L_Idx);
      Global_Result.Update (L_Min, L_Idx);
   end Worker;

   Start_T, End_T : Time;
   Seq_Time, Best_Time, Cur_Time : Integer;
   Best_Threads : Integer := 0;
   Speedup : Float;
   Chunk, Start_Idx, End_Idx : Integer;
   R_Min, R_Idx : Integer;

   function Trim_Int (Item : Integer) return Wide_String is
   begin
      return Trim (Integer'Wide_Image (Item), Ada.Strings.Both);
   end Trim_Int;

begin
   Put_Line ("Генерація масиву...");
   Flush;
   
   Arr := new Int_Array (0 .. Dim - 1);

   Rand_Val.Reset (Gen_Val);
   Rand_Idx.Reset (Gen_Idx);

   for I in 0 .. Dim - 1 loop
      Arr (I) := Rand_Val.Random (Gen_Val);
   end loop;

   declare
      Random_Index : Integer := Rand_Idx.Random (Gen_Idx);
   begin
      Arr (Random_Index) := -1;
   end;

   Put_Line ("Масив згенеровано.");
   Flush;

   Start_T := Clock;
   Find_Min (0, Dim, R_Min, R_Idx);
   End_T := Clock;
   Seq_Time := Integer (To_Duration (End_T - Start_T) * 1000.0);

   Put ("Послідовний пошук: знайдено значення ");
   Put (Trim_Int (R_Min) & " (індекс " & Trim_Int (R_Idx) & ")");
   Put_Line (", за " & Trim_Int (Seq_Time) & " мс");

   Best_Time := Integer'Last;

   for T in 1 .. 10 loop
      declare
         Num_Threads : constant Integer := T * 2;
         Workers : array (1 .. Num_Threads) of Worker;
      begin
         Global_Result.Reset;
         Chunk := Dim / Num_Threads;
         Start_T := Clock;

         for I in 1 .. Num_Threads loop
            Start_Idx := (I - 1) * Chunk;
            if I = Num_Threads then
               End_Idx := Dim;
            else
               End_Idx := Start_Idx + Chunk;
            end if;
            Workers (I).Start (Start_Idx, End_Idx);
         end loop;
      end;

      End_T := Clock;
      Cur_Time := Integer (To_Duration (End_T - Start_T) * 1000.0);

      if Cur_Time < Best_Time then
         Best_Time := Cur_Time;
         Best_Threads := T * 2;
      end if;

      Put (Trim_Int (T * 2) & " потоки(ів) знайшли: ");
      Put ("значення " & Trim_Int (Global_Result.Get_Min));
      Put (" (індекс " & Trim_Int (Global_Result.Get_Idx) & "), за ");
      Put_Line (Trim_Int (Cur_Time) & " мс");
   end loop;

   Speedup := Float (Seq_Time) / Float (Best_Time);
   Put ("Пошук з " & Trim_Int (Best_Threads) & " потоками найшвидший");
   Put (" - " & Trim_Int (Best_Time) & " мс в ");
   Wide_Float_IO.Put (Speedup, Fore => 1, Aft => 2, Exp => 0);
   Put_Line ("x швидше");
end Lab2Ada;