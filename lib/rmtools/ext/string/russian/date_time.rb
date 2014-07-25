module RMTools
  module String
    module Russian
      module DateTime
      
        def digit_date
          gsub(/jan(?:uary)?|янв(?:ар[яь])?/i, '01').
          gsub(/feb(?:ruary)?|фев(?:рал[яь])?/i, '02').
          gsub(/mar(?:ch)?|март?а?/i, '03').
          gsub(/apr(?:il)?|апр(?:ел[яь])?/i, '04').
          gsub(/may|ма[яй]/i, '05').
          gsub(/june?|июн[яь]?/i, '06').
          gsub(/july?|июл[яь]?/i, '07').
          gsub(/aug(?:ust)?|авг(?:уста?)?/i, '08').
          gsub(/sep(?:tember)?|сен(?:тябр[яь])?/i, '09').
          gsub(/oct(?:ober)?|окт(?:ябр[яь])?/i, '10').
          gsub(/nov(?:ember)?|ноя(?:бр[яь])?/i, '11').
          gsub(/dec(?:ember)?|дек(?:абр[яь])?/i, '12')
        end
        
        def tr_date
          gsub(/янв(?:ар[яь])?/i, 'jan').
          gsub(/фев(?:рал[яь])?/i, 'feb').
          gsub(/март?а?/i, 'mar').
          gsub(/апр(?:ел[яь])?/i, 'apr').
          gsub(/ма[яй]/i, 'may').
          gsub(/июн[яь]?/i, 'jun').
          gsub(/июл[яь]?/i, 'jul').
          gsub(/авг(?:уста?)?/i, 'aug').
          gsub(/сен(?:тябр[яь])?/i, 'sep').
          gsub(/окт(?:ябр[яь])?/i, 'oct').
          gsub(/ноя(?:бр[яь])?/i, 'nov').
          gsub(/дек(?:абр[яь])?/i, 'dec')
        end
        
        def digit_nums
          gsub(/один|единица/i, '1').
          gsub(/дв(?:ойк|а)/i, '2').
          gsub(/тр(и|ойка)/i, '3').
          gsub(/чет(?:ыре|в[её]рка)/i, '4').
          gsub(/пят(?:ь|[её]рка)/i, '5').
          gsub(/шест(?:ь|[её]рка)/, '6').
          gsub(/сем(?:ь|[её]рка)/i, '7').
          gsub(/вос(?:емь|ьм[её]рка)/i, '8').
          gsub(/девят(ь|ка)/i, '9').
          gsub(/н[оу]ль/i, '0')
        end
        
      end
    end
  end
end