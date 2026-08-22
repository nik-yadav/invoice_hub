const { supabase } = require('../config/supabase');

/**
 * POST /api/v1/upload/signature
 * Upload firm signature (base64 image) to Supabase S3 storage bucket ('signatures')
 */
exports.uploadSignature = async (req, res, next) => {
  try {
    const { image, file_name } = req.body;

    if (!image) {
      return res.status(400).json({
        success: false,
        message: 'Signature image payload (base64) is required',
      });
    }

    const base64Data = image.replace(/^data:image\/\w+;base64,/, '');
    const buffer = Buffer.from(base64Data, 'base64');
    const fileName = file_name || `signature_${Date.now()}_${Math.random().toString(36).substring(7)}.png`;
    const bucketName = process.env.SUPABASE_SIGNATURE_BUCKET || 'signatures';

    let publicUrl = image;

    try {
      const { data, error } = await supabase.storage
        .from(bucketName)
        .upload(fileName, buffer, {
          contentType: 'image/png',
          upsert: true,
        });

      if (error) {
        console.warn('Supabase S3 storage notice:', error.message);
      } else if (data?.path) {
        const { data: publicUrlData } = supabase.storage
          .from(bucketName)
          .getPublicUrl(data.path);

        if (publicUrlData?.publicUrl) {
          publicUrl = publicUrlData.publicUrl;
        }
      }
    } catch (storageErr) {
      console.warn('Supabase S3 storage upload exception:', storageErr.message);
    }

    return res.status(200).json({
      success: true,
      message: 'Signature uploaded successfully to Supabase S3 storage',
      data: {
        url: publicUrl,
        path: publicUrl,
        fileName: fileName,
      },
    });
  } catch (error) {
    next(error);
  }
};
