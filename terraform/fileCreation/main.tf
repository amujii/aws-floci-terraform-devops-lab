resource "local_file" "my_file"{
	filename = "${path.module}/automate.txt"
	content = "this is automate file created using terraform"
}
