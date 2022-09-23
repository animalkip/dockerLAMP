<html>
<head>
 <title>Milestone 2</title>
 <meta charset="utf-8">
<meta http-equiv="refresh" content="8">
</head>
<?php
$conn = mysqli_connect('contsql-milansterkensweb1', 'user', 'password', 'db');
$query = 'SELECT naam From naam';
$result = mysqli_query($conn, $query);
echo '<h1>';
while($value=$result->fetch_array(MYSQLI_ASSOC)){
echo $value['naam'];
}
echo ' is the king of the world!!!</h1>';
$result->close();
mysqli_close($conn);
?>
</body>
</html>