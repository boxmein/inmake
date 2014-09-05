echo "Testing prefixes."
ruby ../inmake.rb -f ./prefixes.rb -p '#!~$'

echo
echo "Testing postfixes."
ruby ../inmake.rb -f ./postfixes.rb -m '\(^_^)/'

echo
echo "Testing regexes."
ruby ../inmake.rb -f ./regexes.rb -r '~~~' --strip-matched

echo
echo "Testing variables."
ruby ../inmake.rb -f ./variables.rb -a "AWESOME=yes" -a "COOL=no"


echo
echo "Testing default mode: line 2 is command"
ruby ../inmake.rb -f ./default-2.rb

echo 
echo "Testing default mode: line 2 is encoding, line 3 is command"
ruby ../inmake.rb -f ./default-3.rb