function []=describe(image_or_folder, output_folder, enable_normalization)
    % image_or_folder = path to a folder containing images or to a single image;
    % output_folder = path to a folder; we will save the features there;
    % enable_normalization = normalize features after extraction; default = true.

    if ~exist('image_or_folder', 'var')
    	throw(MException('extra:image_or_folder', 'ERROR: Parameter image_or_folder is empty.'));
    end
    if ~exist('output_folder', 'var')
    	throw(MException('extra:output_folder', 'ERROR: Parameter output_folder is empty.'));
    end
    if ~exist('enable_normalization', 'var')
    	enable_normalization = true;
    end

    addpath('..');
    fcommon = BaseFunctions.getInstance;

	if ~exist('matconvnet-1.0-beta18', 'dir')
		untar('http://www.vlfeat.org/matconvnet/download/matconvnet-1.0-beta18.tar.gz');
		cd matconvnet-1.0-beta18;
		run matlab/vl_compilenn;
		cd ..;
	end
	
	if ~exist('imagenet-vgg-m.mat', 'file')
		urlwrite('http://www.vlfeat.org/matconvnet/models/beta18/imagenet-vgg-m.mat', 'imagenet-vgg-m.mat') ;
	end

	fprintf('Starting MatConvNet...\n');
	
	cd matconvnet-1.0-beta18;
	run matlab/vl_setupnn
	cd ..;

	fprintf('Loading VGG-M...\n');
	net = load('imagenet-vgg-m.mat');

	nfiles = 0;
	if isdir(image_or_folder)
		fprintf('Gathering the list of images to be described...\n');
        files = dir(image_or_folder);
		files = {files(~[files.isdir]).name};
		tot_files = length(files);
		for nfiles = 1:tot_files
			file = files(nfiles);
			fprintf('Describing %d of %d: ''%s''...\n', nfiles, tot_files, char(file));
			try
				im = imread(sprintf('%s/%s', image_or_folder, char(file)));
			catch exception
				fprintf('!!!!! WARNING: Impossible to open ''%s'', file ignored.\n', char(file));
				continue;
			end
			im_ = single(im);
			im_ = imresize(im_, net.meta.normalization.imageSize(1:2));
			im_ = im_ - net.meta.normalization.averageImage;
	        res = vl_simplenn(net, im_);
	        raw = res(19+1).x;
	        if enable_normalization
	        	val = squeeze(double(raw));
				no = norm(val);
				feature_vector = squeeze(raw ./ no)';
			else
				feature_vector = squeeze(raw)';
	        end
			[ign, file, ext] = fileparts(char(file));
			fcommon.save_feature_vector(feature_vector, sprintf('%s/%s', output_folder, char(file)));
		end
    else
    	nfiles = 1;
    	[ign, file, ext] = fileparts(image_or_folder);
    	files = sprintf('%s.%s', char(file), char(ext));
		fprintf('Describing ''%s''...\n', file);
		im = imread(image_or_folder);
		im_ = single(im);
		im_ = imresize(im_, net.meta.normalization.imageSize(1:2));
		im_ = im_ - net.meta.normalization.averageImage;
        res = vl_simplenn(net, im_);
        raw = res(19+1).x;
        if enable_normalization
        	val = squeeze(double(raw));
			no = norm(val);
			feature_vector = squeeze(raw ./ no)';
		else
			feature_vector = squeeze(raw)';
        end
		fcommon.save_feature_vector(feature_vector, sprintf('%s/%s', output_folder, char(file)));
    end
    fprintf('Done processing %d files.\n\n', nfiles);
end
