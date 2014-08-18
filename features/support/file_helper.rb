def touch_tempfile filename
	FileUtils.mkdir_p File.dirname filename
	FileUtils.touch (filename)
	@step_tempfiles << filename
end

def remove_all_tempfiles
	@step_tempfiles.each do |tempfile|
		File.unlink tempfile
	end
end

def clear_tempfile_list
	@step_tempfiles = []
end