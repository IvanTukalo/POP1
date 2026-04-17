with Ada.Wide_Text_IO; use Ada.Wide_Text_IO;
with Ada.Strings.Wide_Fixed; use Ada.Strings.Wide_Fixed;
with Ada.Strings; use Ada.Strings;
with GNAT.Semaphores; use GNAT.Semaphores;
with Ada.Unchecked_Deallocation;

procedure Lab4Ada is

   package Wide_Int_IO is new Ada.Wide_Text_IO.Integer_IO (Integer);
   use Wide_Int_IO;

   Num_Philosophers : constant Integer := 5;

   type Semaphore_Access is access Counting_Semaphore;
   type Fork_Array is array (0 .. Num_Philosophers - 1) of Semaphore_Access;
   
   procedure Free_Semaphore is new Ada.Unchecked_Deallocation
     (Object => Counting_Semaphore, Name => Semaphore_Access);

   Mode : Integer;

   function Trim_Int (Item : Integer) return Wide_String is
   begin
      return Trim (Integer'Wide_Image (Item), Ada.Strings.Both);
   end Trim_Int;

   -- =========================================================
   -- СТВОРЕННЯ ЗАХИЩЕНОГО ОБ'ЄКТА ДЛЯ ПОТОКОБЕЗПЕЧНОГО ВИВОДУ
   -- =========================================================
   protected Safe_Console is
      procedure Print_Line (Message : Wide_String);
   end Safe_Console;

   protected body Safe_Console is
      procedure Print_Line (Message : Wide_String) is
      begin
         -- Лише один потік одночасно може виконувати цю інструкцію
         Put_Line (Message);
      end Print_Line;
   end Safe_Console;
   -- =========================================================

   procedure Run_Asymmetric_Philosopher is
      Forks : Fork_Array;
   begin
      for I in 0 .. Num_Philosophers - 1 loop
         Forks (I) := new Counting_Semaphore (1, Default_Ceiling);
      end loop;

      declare
         Completion_Semaphore : Counting_Semaphore (0, Default_Ceiling);

         task type Philosopher is
            entry Start (Start_ID : Integer);
         end Philosopher;

         task body Philosopher is
            ID, Right_Fork, Left_Fork : Integer;
         begin
            accept Start (Start_ID : Integer) do
               ID := Start_ID;
               Right_Fork := ID;
               Left_Fork := (ID + 1) mod Num_Philosophers;
            end Start;

            begin -- Блок безпеки від падіння потоку
               for I in 1 .. 10 loop
                  Safe_Console.Print_Line ("Філософ " & Trim_Int (ID + 1) & " думає " & Trim_Int (I) & " раз");
                  delay 0.01;

                  if ID = 4 then
                     Forks (Left_Fork).Seize;
                     Forks (Right_Fork).Seize;
                  else
                     Forks (Right_Fork).Seize;
                     Forks (Left_Fork).Seize;
                  end if;

                  Safe_Console.Print_Line ("Філософ " & Trim_Int (ID + 1) & " їсть " & Trim_Int (I) & " раз");
                  delay 0.01;

                  if ID = 4 then
                     Forks (Right_Fork).Release;
                     Forks (Left_Fork).Release;
                  else
                     Forks (Left_Fork).Release;
                     Forks (Right_Fork).Release;
                  end if;
               end loop;
            exception
               when others =>
                  Safe_Console.Print_Line ("Помилка в потоці філософа " & Trim_Int(ID + 1));
            end;

            Completion_Semaphore.Release;
         end Philosopher;

         Philosophers : array (0 .. Num_Philosophers - 1) of Philosopher;
      begin
         for I in 0 .. Num_Philosophers - 1 loop
            Philosophers (I).Start (I);
         end loop;

         for I in 1 .. Num_Philosophers loop
            Completion_Semaphore.Seize;
         end loop;
      end;

      for I in 0 .. Num_Philosophers - 1 loop
         Free_Semaphore (Forks (I));
      end loop;
   end Run_Asymmetric_Philosopher;

   procedure Run_Limited_Access is
      Forks : Fork_Array;
   begin
      for I in 0 .. Num_Philosophers - 1 loop
         Forks (I) := new Counting_Semaphore (1, Default_Ceiling);
      end loop;

      declare
         Completion_Semaphore : Counting_Semaphore (0, Default_Ceiling);
         Limit_Semaphore      : Counting_Semaphore (Num_Philosophers - 1, Default_Ceiling);

         task type Philosopher is
            entry Start (Start_ID : Integer);
         end Philosopher;

         task body Philosopher is
            ID, Right_Fork, Left_Fork : Integer;
         begin
            accept Start (Start_ID : Integer) do
               ID := Start_ID;
               Right_Fork := ID;
               Left_Fork := (ID + 1) mod Num_Philosophers;
            end Start;

            begin
               for I in 1 .. 10 loop
                  Safe_Console.Print_Line ("Філософ " & Trim_Int (ID + 1) & " думає " & Trim_Int (I) & " раз");
                  delay 0.01;

                  Limit_Semaphore.Seize;
                  Forks (Right_Fork).Seize;
                  Forks (Left_Fork).Seize;

                  Safe_Console.Print_Line ("Філософ " & Trim_Int (ID + 1) & " їсть " & Trim_Int (I) & " раз");
                  delay 0.01;

                  Forks (Left_Fork).Release;
                  Forks (Right_Fork).Release;
                  Limit_Semaphore.Release;
               end loop;
            exception
               when others =>
                  Safe_Console.Print_Line ("Помилка в потоці філософа " & Trim_Int(ID + 1));
            end;

            Completion_Semaphore.Release;
         end Philosopher;

         Philosophers : array (0 .. Num_Philosophers - 1) of Philosopher;
      begin
         for I in 0 .. Num_Philosophers - 1 loop
            Philosophers (I).Start (I);
         end loop;

         for I in 1 .. Num_Philosophers loop
            Completion_Semaphore.Seize;
         end loop;
      end;

      for I in 0 .. Num_Philosophers - 1 loop
         Free_Semaphore (Forks (I));
      end loop;
   end Run_Limited_Access;

   procedure Run_Waiters is
      Forks : Fork_Array;
   begin
      for I in 0 .. Num_Philosophers - 1 loop
         Forks (I) := new Counting_Semaphore (1, Default_Ceiling);
      end loop;

      declare
         Completion_Semaphore : Counting_Semaphore (0, Default_Ceiling);
         Waiters_Semaphore    : Counting_Semaphore (2, Default_Ceiling);

         task type Philosopher is
            entry Start (Start_ID : Integer);
         end Philosopher;

         task body Philosopher is
            ID, Right_Fork, Left_Fork : Integer;
         begin
            accept Start (Start_ID : Integer) do
               ID := Start_ID;
               Right_Fork := ID;
               Left_Fork := (ID + 1) mod Num_Philosophers;
            end Start;

            begin
               for I in 1 .. 10 loop
                  Safe_Console.Print_Line ("Філософ " & Trim_Int (ID + 1) & " думає " & Trim_Int (I) & " раз");
                  delay 0.01;

                  Waiters_Semaphore.Seize;
                  Forks (Right_Fork).Seize;
                  Forks (Left_Fork).Seize;

                  Safe_Console.Print_Line ("Філософ " & Trim_Int (ID + 1) & " їсть " & Trim_Int (I) & " раз");
                  delay 0.01;

                  Forks (Left_Fork).Release;
                  Forks (Right_Fork).Release;
                  Waiters_Semaphore.Release;
               end loop;
            exception
               when others =>
                  Safe_Console.Print_Line ("Помилка в потоці філософа " & Trim_Int(ID + 1));
            end;

            Completion_Semaphore.Release;
         end Philosopher;

         Philosophers : array (0 .. Num_Philosophers - 1) of Philosopher;
      begin
         for I in 0 .. Num_Philosophers - 1 loop
            Philosophers (I).Start (I);
         end loop;

         for I in 1 .. Num_Philosophers loop
            Completion_Semaphore.Seize;
         end loop;
      end;

      for I in 0 .. Num_Philosophers - 1 loop
         Free_Semaphore (Forks (I));
      end loop;
   end Run_Waiters;

   procedure Run_Try_Lock is
      Forks : Fork_Array;
   begin
      for I in 0 .. Num_Philosophers - 1 loop
         Forks (I) := new Counting_Semaphore (1, Default_Ceiling);
      end loop;

      declare
         Completion_Semaphore : Counting_Semaphore (0, Default_Ceiling);

         task type Philosopher is
            entry Start (Start_ID : Integer);
         end Philosopher;

         task body Philosopher is
            ID, Right_Fork, Left_Fork : Integer;
         begin
            accept Start (Start_ID : Integer) do
               ID := Start_ID;
               Right_Fork := ID;
               Left_Fork := (ID + 1) mod Num_Philosophers;
            end Start;

            begin
               for I in 1 .. 10 loop
                  Safe_Console.Print_Line ("Філософ " & Trim_Int (ID + 1) & " думає " & Trim_Int (I) & " раз");
                  delay 0.01;

                  loop
                     Forks (Right_Fork).Seize;

                     select
                        Forks (Left_Fork).Seize;
                        exit;
                     else
                        Forks (Right_Fork).Release;
                        delay 0.005;
                     end select;
                  end loop;

                  Safe_Console.Print_Line ("Філософ " & Trim_Int (ID + 1) & " їсть " & Trim_Int (I) & " раз");
                  delay 0.01;

                  Forks (Left_Fork).Release;
                  Forks (Right_Fork).Release;
               end loop;
            exception
               when others =>
                  Safe_Console.Print_Line ("Помилка в потоці філософа " & Trim_Int(ID + 1));
            end;

            Completion_Semaphore.Release;
         end Philosopher;

         Philosophers : array (0 .. Num_Philosophers - 1) of Philosopher;
      begin
         for I in 0 .. Num_Philosophers - 1 loop
            Philosophers (I).Start (I);
         end loop;

         for I in 1 .. Num_Philosophers loop
            Completion_Semaphore.Seize;
         end loop;
      end;

      for I in 0 .. Num_Philosophers - 1 loop
         Free_Semaphore (Forks (I));
      end loop;
   end Run_Try_Lock;

begin
   loop
      Put_Line ("Оберіть метод вирішення проблеми взаємного блокування");
      Put_Line ("1 - Асиметричний філософ (зміна порядку вилок для 5-го)");
      Put_Line ("2 - Обмеження доступу (не більше 4 філософів за столом)");
      Put_Line ("3 - Офіціанти (лише 2 філософи можуть їсти одночасно)");
      Put_Line ("4 - Відмова від очікування (покласти вилку, якщо друга зайнята)");
      Put_Line ("0 - Вихід");

      loop
         begin
            Get (Mode);
            if Mode >= 0 and then Mode <= 4 then
               Skip_Line;
               exit;
            end if;
            Put_Line ("Помилка вводу. Введіть число від 0 до 4.");
         exception
            when Data_Error =>
               Put_Line ("Помилка вводу. Введіть число від 0 до 4.");
               Skip_Line;
         end;
      end loop;

      exit when Mode = 0;

      New_Line;
      Put_Line ("Запуск Рішення " & Trim_Int (Mode) & " (15 ітерацій)...");
      New_Line;

      for Test in 1 .. 15 loop
         Put_Line ("--- Ітерація " & Trim_Int (Test) & " ---");

         if Mode = 1 then
            Run_Asymmetric_Philosopher;
         elsif Mode = 2 then
            Run_Limited_Access;
         elsif Mode = 3 then
            Run_Waiters;
         elsif Mode = 4 then
            Run_Try_Lock;
         end if;

         Put_Line ("--- Ітерація " & Trim_Int (Test) & " успішно завершена ---");
         New_Line;
      end loop;
   end loop;
end Lab4Ada;