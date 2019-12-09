require 'reverse_markdown'

Comment.where("text LIKE '%sconnect-is-installed%'").delete_all
Comment.where("text LIKE '%ConnectiveDocSignExtentionInstalled%'").delete_all
Comment.where("text = ''").delete_all

comments = Comment.all
comments.each do |c|

  t = ReverseMarkdown.convert( c.text )
  t.sub!("&nbsp;"," ")
  #skip validation AND updated_at
  c.update_column("text",t)

end
