with Ada.Wide_Text_IO; use Ada.Wide_Text_IO;
with Ada.Strings.Wide_Fixed; use Ada.Strings.Wide_Fixed;
with Ada.Strings; use Ada.Strings;
with GNAT.Semaphores; use GNAT.Semaphores;
with Ada.Numerics.Discrete_Random;
with Ada.Unchecked_Deallocation;

procedure Lab3Ada is

   package Wide_Int_IO is new Ada.Wide_Text_IO.Integer_IO (Integer);
   use Wide_Int_IO;

   type Int_Array is array (Positive range <>) of Integer;
   type Int_Array_Access is access Int_Array;
   
   procedure Free_Int_Array is new Ada.Unchecked_Deallocation
     (Object => Int_Array, Name => Int_Array_Access);

   subtype Rand_Range is Integer range 1 .. 100;
   package Random_Gen is new Ada.Numerics.Discrete_Random (Rand_Range);
   Gen : Random_Gen.Generator;

   Mode, Num_Producers, Num_Consumers, Capacity : Integer;
   Total_Items : Integer;
   Producer_Items : Int_Array_Access;

   function Trim_Int (Item : Integer) return Wide_String is
   begin
      return Trim (Integer'Wide_Image (Item), Ada.Strings.Both);
   end Trim_Int;

begin
   Random_Gen.Reset (Gen);

   loop
      Put_Line ("Оберіть режим роботи (1 - Випадкова генерація, 2 - Ручне введення)");
      loop
         begin
            Get (Mode);
            if Mode = 0 or else Mode = 1 or else Mode = 2 then
               Skip_Line;
               exit;
            end if;
            Put_Line ("Помилка вводу. Введіть 1 або 2.");
         exception
            when Data_Error =>
               Put_Line ("Помилка вводу. Введіть 1 або 2.");
               Skip_Line;
         end;
      end loop;

      if Mode = 2 then
         loop
            Put_Line ("Введіть кількість Виробників, Споживачів");
            Put_Line ("та максимальну місткість сховища через пробіл:");
            begin
               Get (Num_Producers);
               Get (Num_Consumers);
               Get (Capacity);
               if Num_Producers > 0 and then Num_Consumers > 0
                 and then Capacity > 0
               then
                  Skip_Line;
                  exit;
               end if;
               Put_Line ("Помилка. Введіть три додатні цілі числа.");
            exception
               when Data_Error =>
                  Put_Line ("Помилка. Введіть три додатні цілі числа.");
                  Skip_Line;
            end;
         end loop;

         Producer_Items := new Int_Array (1 .. Num_Producers);
         
         loop
            Put_Line ("Введіть кількість товарів яку створюватимуть " &
                      "Виробники в кількості " & Trim_Int (Num_Producers) & 
                      " через пробіл:");
            declare
               All_Valid : Boolean := True;
            begin
               for I in 1 .. Num_Producers loop
                  Get (Producer_Items (I));
                  if Producer_Items (I) <= 0 then
                     All_Valid := False;
                  end if;
               end loop;
               
               if All_Valid then
                  Skip_Line;
                  exit;
               else
                  Put_Line ("Помилка. Числа мають бути додатними.");
                  Skip_Line;
               end if;
            exception
               when Data_Error =>
                  Put_Line ("Помилка. Необхідно ввести числа.");
                  Skip_Line;
            end;
         end loop;

      elsif Mode = 0 then
         exit;
      else
         Num_Producers := (Random_Gen.Random (Gen) mod 2) + 1;
         Num_Consumers := (Random_Gen.Random (Gen) mod 2) + 1;
         Capacity := (Random_Gen.Random (Gen) mod 4) + 2;
         
         Producer_Items := new Int_Array (1 .. Num_Producers);
         for I in 1 .. Num_Producers loop
            Producer_Items (I) := (Random_Gen.Random (Gen) mod 10) + 5;
         end loop;
      end if;

      Total_Items := 0;
      for I in 1 .. Num_Producers loop
         Total_Items := Total_Items + Producer_Items (I);
      end loop;

      New_Line;
      Put_Line ("Вмістимість сховища - " & Trim_Int (Capacity));
      Put_Line ("Кількість споживачів - " & Trim_Int (Num_Consumers));
      Put_Line ("Загальна кількість товарів що будуть створені " &
                "і спожиті - " & Trim_Int (Total_Items));
      
      for I in 1 .. Num_Producers loop
         Put_Line (Trim_Int (I) & " виробник - " &
                   Trim_Int (Producer_Items (I)) & " товарів");
      end loop;
      New_Line;

      declare
         Access_Mutex : Counting_Semaphore (1, Default_Ceiling);
         Empty_Slots  : Counting_Semaphore (Capacity, Default_Ceiling);
         Filled_Slots : Counting_Semaphore (0, Default_Ceiling);

         Current_Storage_Count : Integer := 0;
         Global_Consumed       : Integer := 0;

         task type Producer is
            entry Start (Start_ID, Start_Items : Integer);
         end Producer;

         task type Consumer is
            entry Start (Start_ID : Integer);
         end Consumer;

         task body Producer is
            ID, Items : Integer;
            Personal_Produced : Integer := 0;
         begin
            accept Start (Start_ID, Start_Items : Integer) do
               ID := Start_ID;
               Items := Start_Items;
            end Start;

            while Personal_Produced < Items loop
               Empty_Slots.Seize;
               Access_Mutex.Seize;

               Current_Storage_Count := Current_Storage_Count + 1;
               Personal_Produced := Personal_Produced + 1;

               if Personal_Produced = Items then
                  Put_Line (Trim_Int (ID) & " Виробник завершив свою роботу, " &
                            "створено " & Trim_Int (Personal_Produced) & 
                            " товарів, заповненість " & 
                            Trim_Int (Current_Storage_Count));
               else
                  Put_Line (Trim_Int (ID) & " Виробник поклав свій " &
                            Trim_Int (Personal_Produced) & " товар на склад, " &
                            "заповненість " & Trim_Int (Current_Storage_Count));
               end if;

               Access_Mutex.Release;
               Filled_Slots.Release;
            end loop;
         end Producer;

         task body Consumer is
            ID : Integer;
            Personal_Consumed : Integer := 0;
            Finished_All : Boolean;
         begin
            accept Start (Start_ID : Integer) do
               ID := Start_ID;
            end Start;

            loop
               Filled_Slots.Seize;
               Access_Mutex.Seize;

               if Global_Consumed >= Total_Items then
                  Access_Mutex.Release;
                  Filled_Slots.Release;
                  exit;
               end if;

               Current_Storage_Count := Current_Storage_Count - 1;
               Global_Consumed := Global_Consumed + 1;
               Personal_Consumed := Personal_Consumed + 1;

               Put_Line (Trim_Int (ID) & " Споживач спожив " &
                         Trim_Int (Personal_Consumed) & " товар на складі, " &
                         "заповненість " & Trim_Int (Current_Storage_Count));

               Finished_All := (Global_Consumed = Total_Items);

               Access_Mutex.Release;
               Empty_Slots.Release;

               if Finished_All then
                  for I in 1 .. Num_Consumers loop
                     Filled_Slots.Release;
                  end loop;
                  exit;
               end if;
            end loop;
         end Consumer;

         Producers : array (1 .. Num_Producers) of Producer;
         Consumers : array (1 .. Num_Consumers) of Consumer;

      begin
         for I in 1 .. Num_Producers loop
            Producers (I).Start (I, Producer_Items (I));
         end loop;

         for I in 1 .. Num_Consumers loop
            Consumers (I).Start (I);
         end loop;
      end;

      Put_Line ("Усі потоки успішно завершили роботу.");
      New_Line;

      Free_Int_Array (Producer_Items);
   end loop;
end Lab3Ada;